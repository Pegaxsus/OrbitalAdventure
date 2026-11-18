using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Text;
using System.Windows.Forms;

[DataContract] sealed class StationDesign
{
    [DataMember] public int Version=1;
    [DataMember] public float OriginX,OriginY,ExportOriginX,ExportOriginY;
    [DataMember] public int ExportSize;
    [DataMember] public float UnitsPerPixel=1;
    [DataMember] public List<DesignAsset> Assets=new List<DesignAsset>();
    [DataMember] public List<DesignLayer> Layers=new List<DesignLayer>();
    [DataMember] public List<DesignPoint> Hardpoints=new List<DesignPoint>();
}
[DataContract] sealed class DesignAsset
{
    [DataMember] public string Id,Name,Png;
}
[DataContract] sealed class DesignLayer
{
    [DataMember] public string Asset,Name;
    [DataMember] public float X,Y,Angle,Scale=1;
    [DataMember(EmitDefaultValue=false)] public float? ScaleX,ScaleY;
}
[DataContract] sealed class DesignPoint
{
    [DataMember] public string Kind;
    [DataMember] public float X,Y,Angle;
}
sealed class StationBuilder : Form
{
    const float NormalLength=164,NormalWidth=58,DreadLength=258,DreadWidth=196;
    const int MaxExportSize=4096;
    static readonly CultureInfo Numbers=CultureInfo.InvariantCulture;
    sealed class Asset : IDisposable
    {
        public string Id,Name; public byte[] Png; public Bitmap Image;
        public void Dispose() {Image.Dispose();}
    }
    abstract class Item
    {
        public float X,Y,Angle;
        public Item Copy() { return (Item)MemberwiseClone(); }
    }
    sealed class Layer : Item
    {
        public Asset Asset; public string Name;
        public float ScaleX=1,ScaleY=1;
        public float Scale {get {return Math.Max(ScaleX,ScaleY);} set {ScaleX=ScaleY=value;}}
        public override string ToString() {return Name;}
    }
    sealed class Mount : Item
    {
        public string Kind;
        public override string ToString() {return Kind=="normal" ? "Puerto normal" : Kind=="dread" ? "Puerto Dread" : "PDC";}
    }
    sealed class WorkCanvas : Panel
    {
        public WorkCanvas() {DoubleBuffered=true;ResizeRedraw=true;SetStyle(ControlStyles.Selectable,true);TabStop=true;}
    }
    sealed class OutputFile
    {
        public string Path,Temporary,Backup;
        public bool Installed;
    }

    readonly List<Asset> assets=new List<Asset>();
    readonly List<Layer> layers=new List<Layer>();
    readonly List<Mount> mounts=new List<Mount>();
    readonly WorkCanvas canvas=new WorkCanvas {Dock=DockStyle.Fill,AllowDrop=true,BackColor=Color.FromArgb(12,20,34)};
    readonly ListBox layerList=new ListBox {Dock=DockStyle.Fill};
    readonly ListBox mountList=new ListBox {Dock=DockStyle.Fill};
    readonly ComboBox mode=new ComboBox {DropDownStyle=ComboBoxStyle.DropDownList,Width=190};
    readonly TextBox nameBox=new TextBox {Width=150};
    readonly NumericUpDown positionX=Number(-10000,10000,0),positionY=Number(-10000,10000,0);
    readonly NumericUpDown rotation=Number(-360,360,1),scale=Number(1,2000,1);
    readonly NumericUpDown scaleX=Number(1,2000,1),scaleY=Number(1,2000,1);
    readonly Label selectionLabel=new Label {AutoSize=true,MaximumSize=new Size(265,0)};
    readonly Label status=new Label {Dock=DockStyle.Bottom,Height=45,Padding=new Padding(10,4,5,0)};
    readonly Button duplicateButton,frontButton,backButton;
    readonly ContextMenuStrip selectionMenu=new ContextMenuStrip();
    readonly List<Item> clipboard=new List<Item>();
    readonly HashSet<Item> selection=new HashSet<Item>();
    Dictionary<Item,PointF> dragOrigins;
    PointF pastePosition;
    Item SingleSelection
    {
        get
        {
            if(selection.Count!=1) return null;
            foreach(Item item in selection) return item;
            return null;
        }
    }
    Layer selectedLayer {get {return SingleSelection as Layer;}}
    Mount selectedMount {get {return SingleSelection as Mount;}}
    PointF origin,viewCenter,worldStart,panStart;
    Point mouseStart;
    float zoom=1;
    bool refreshing,dirty,dragging,panning,rightPending,scaling,rotating;
    float transformStartAngle,transformStartPointer,transformStartRadius;
    float startScaleX,startScaleY;
    int stretchAxis,stretchSide;
    PointF transformCenter;
    string exportPath,projectPath;

    static NumericUpDown Number(int min,int max,int decimals)
    {
        return new NumericUpDown {Minimum=min,Maximum=max,DecimalPlaces=decimals,Width=112,Increment=decimals==0 ? 1 : 5};
    }
    static Button ButtonFor(string text,Action action)
    {
        var button=new Button {Text=text,AutoSize=true,Height=30};
        button.Click+=delegate {action();};return button;
    }
    static Control Field(string caption,Control input)
    {
        var row=new FlowLayoutPanel {Width=275,Height=32,WrapContents=false};
        row.Controls.Add(new Label {Text=caption,Width=100,Padding=new Padding(0,4,0,0)});
        row.Controls.Add(input);return row;
    }
    StationBuilder()
    {
        Text="stationBuilder 1.3 · Editor de estaciones";
        ClientSize=new Size(1280,820);MinimumSize=new Size(1080,670);
        Font=new Font("Segoe UI",10);KeyPreview=true;
        var toolbar=new FlowLayoutPanel {Dock=DockStyle.Top,Height=86,Padding=new Padding(7)};
        toolbar.Controls.Add(ButtonFor("Nuevo",NewDesign));
        toolbar.Controls.Add(ButtonFor("Abrir proyecto…",OpenDesign));
        toolbar.Controls.Add(ButtonFor("Añadir PNG…",PickPng));
        duplicateButton=ButtonFor("Duplicar",DuplicateSelected);
        frontButton=ButtonFor("Al frente",delegate {Reorder(true);});
        backButton=ButtonFor("Al fondo",delegate {Reorder(false);});
        toolbar.Controls.Add(duplicateButton);
        toolbar.Controls.Add(ButtonFor("Eliminar",DeleteSelected));
        toolbar.Controls.Add(frontButton);toolbar.Controls.Add(backButton);

        toolbar.Controls.Add(ButtonFor("Guardar proyecto…",SaveProject));
        toolbar.Controls.Add(ButtonFor("Exportar PNG…",SaveDesign));
        mode.Items.AddRange(new object[] {"Seleccionar / mover","Colocar puerto normal","Colocar puerto Dread","Colocar PDC","Situar origen"});
        mode.SelectedIndex=0;toolbar.Controls.Add(mode);
        toolbar.Controls.Add(ButtonFor("Centrar vista",FitView));
        var sidebar=new Panel {Dock=DockStyle.Right,Width=300,Padding=new Padding(10)};
        var tabs=new TabControl {Dock=DockStyle.Fill};
        var tabLayers=new TabPage("Capas · frente arriba");
        var tabPoints=new TabPage("Hardpoints");
        tabLayers.Controls.Add(layerList);tabPoints.Controls.Add(mountList);
        tabs.TabPages.Add(tabLayers);tabs.TabPages.Add(tabPoints);
        var properties=new FlowLayoutPanel {Dock=DockStyle.Bottom,Height=310,FlowDirection=FlowDirection.TopDown,WrapContents=false};
        properties.Controls.Add(selectionLabel);properties.Controls.Add(Field("Nombre",nameBox));
        properties.Controls.Add(Field("Posición X",positionX));properties.Controls.Add(Field("Posición Y",positionY));
        properties.Controls.Add(Field("Rotación °",rotation));properties.Controls.Add(Field("Escala %",scale));
        properties.Controls.Add(Field("Escala X %",scaleX));properties.Controls.Add(Field("Escala Y %",scaleY));
        properties.Controls.Add(new Label {AutoSize=true,MaximumSize=new Size(270,0),Text="Puertos fijos: normal 164 × 58 · Dread 258 × 196. El eje largo indica la orientación de atraque."});
        sidebar.Controls.Add(tabs);sidebar.Controls.Add(properties);
        Controls.Add(canvas);Controls.Add(sidebar);Controls.Add(toolbar);Controls.Add(status);
        layerList.SelectedIndexChanged+=delegate {
            if(refreshing || layerList.SelectedIndex<0) return;
            SelectOnly((Layer)layerList.SelectedItem);RefreshSelection();
        };
        mountList.SelectedIndexChanged+=delegate {
            if(refreshing || mountList.SelectedIndex<0) return;
            SelectOnly((Mount)mountList.SelectedItem);RefreshSelection();
        };
        nameBox.TextChanged+=delegate {
            if(refreshing || selectedLayer==null) return;
            selectedLayer.Name=nameBox.Text;Changed();RefreshLists();
        };
        positionX.ValueChanged+=PropertyChanged;positionY.ValueChanged+=PropertyChanged;
        rotation.ValueChanged+=PropertyChanged;scale.ValueChanged+=PropertyChanged;
        scaleX.ValueChanged+=PropertyChanged;scaleY.ValueChanged+=PropertyChanged;
        mode.SelectedIndexChanged+=delegate {UpdateStatus();};
        canvas.Paint+=PaintCanvas;canvas.MouseDown+=CanvasDown;canvas.MouseMove+=CanvasMove;canvas.MouseWheel+=CanvasWheel;
        canvas.MouseUp+=CanvasUp;
        canvas.MouseCaptureChanged+=delegate {
            if(!canvas.Capture)
            {
                dragging=panning=rightPending=scaling=rotating=false;
                stretchAxis=0;
            }
        };
        selectionMenu.Items.Add("Eliminar",null,delegate {DeleteSelected();});
        selectionMenu.Items.Add("Traer al frente",null,delegate {Reorder(true);});
        selectionMenu.Items.Add("Enviar al fondo",null,delegate {Reorder(false);});
        selectionMenu.Items.Add(new ToolStripSeparator());
        selectionMenu.Items.Add("Copiar",null,delegate {CopySelection();});
        selectionMenu.Items.Add("Pegar aquí",null,delegate {PasteSelection(pastePosition);});
        selectionMenu.Items.Add("Duplicar",null,delegate {DuplicateSelected();});
        selectionMenu.Items.Add("Girar 90° a la izquierda",null,delegate {RotateSelection(-90);});
        selectionMenu.Items.Add("Girar 90° a la derecha",null,delegate {RotateSelection(90);});
        canvas.DragEnter+=delegate(object sender,DragEventArgs e) {
            e.Effect=e.Data.GetDataPresent(DataFormats.FileDrop) ? DragDropEffects.Copy : DragDropEffects.None;
        };
        canvas.DragDrop+=delegate(object sender,DragEventArgs e) {
            var files=e.Data.GetData(DataFormats.FileDrop) as string[];
            if(files==null) return;
            try {AddFiles(files,ToWorld(canvas.PointToClient(new Point(e.X,e.Y))));}
            catch(Exception error) {ShowError(error);}
        };
        FormClosing+=delegate(object sender,FormClosingEventArgs e) {e.Cancel=!ConfirmDiscard();};
        Shown+=delegate {canvas.Focus();};
        mode.SelectedIndex=0;RefreshLists();RefreshSelection();
    }
    void ShowError(Exception error) {MessageBox.Show(this,error.Message,"stationBuilder",MessageBoxButtons.OK,MessageBoxIcon.Error);}
    void Changed() {dirty=true;canvas.Invalidate();UpdateStatus();}
    void UpdateStatus()
    {
        status.Text=(dirty ? "Cambios pendientes · " : "")+layers.Count+" capas · "+mounts.Count+" hardpoints · Zoom "+Math.Round(zoom*100)+
            "%\nEsquinas: escala · Rombos: X/Y · Círculo: giro · Clic derecho: menú · Arrastre derecho/central: plano";
    }
    void RefreshLists()
    {
        refreshing=true;layerList.Items.Clear();
        for(int i=layers.Count-1;i>=0;i--) layerList.Items.Add(layers[i]);
        mountList.Items.Clear();foreach(Mount mount in mounts) mountList.Items.Add(mount);
        layerList.SelectedItem=selectedLayer;mountList.SelectedItem=selectedMount;refreshing=false;
    }
    void RefreshSelection()
    {
        refreshing=true;layerList.SelectedItem=selectedLayer;mountList.SelectedItem=selectedMount;
        bool selected=selectedLayer!=null || selectedMount!=null;
        selectionLabel.Text=selection.Count>1 ? selection.Count+" objetos seleccionados" : selectedLayer!=null ? "Capa seleccionada" : selectedMount!=null ? selectedMount.ToString() : "Selecciona una capa o hardpoint";
        nameBox.Enabled=scale.Enabled=selectedLayer!=null;
        duplicateButton.Enabled=CanInsert(OrderedSelection());
        frontButton.Enabled=backButton.Enabled=layers.Exists(layer => selection.Contains(layer));
        scaleX.Enabled=scaleY.Enabled=selectedLayer!=null;
        positionX.Enabled=positionY.Enabled=rotation.Enabled=selected;
        nameBox.Text=selectedLayer!=null ? selectedLayer.Name : "";
        if(selected)
        {
            positionX.Value=(decimal)(selectedLayer!=null ? selectedLayer.X : selectedMount.X);

            positionY.Value=(decimal)(selectedLayer!=null ? selectedLayer.Y : selectedMount.Y);
            rotation.Value=(decimal)(selectedLayer!=null ? selectedLayer.Angle : selectedMount.Angle);
        }
        scale.Value=(decimal)(selectedLayer!=null ? selectedLayer.Scale*100 : 100);
        scaleX.Value=(decimal)(selectedLayer!=null ? selectedLayer.ScaleX*100 : 100);
        scaleY.Value=(decimal)(selectedLayer!=null ? selectedLayer.ScaleY*100 : 100);
        refreshing=false;canvas.Invalidate();UpdateStatus();
    }
    void PropertyChanged(object sender,EventArgs e)
    {
        if(refreshing) return;
        if(selectedLayer!=null)
        {
            selectedLayer.X=(float)positionX.Value;selectedLayer.Y=(float)positionY.Value;
            selectedLayer.Angle=(float)rotation.Value;
            if(sender==scale) ScaleProportionally(selectedLayer,selectedLayer.ScaleX,selectedLayer.ScaleY,(float)scale.Value/100/selectedLayer.Scale);
            if(sender==scaleX) selectedLayer.ScaleX=(float)scaleX.Value/100;
            if(sender==scaleY) selectedLayer.ScaleY=(float)scaleY.Value/100;
        }
        else if(selectedMount!=null)
        {
            selectedMount.X=(float)positionX.Value;selectedMount.Y=(float)positionY.Value;
            selectedMount.Angle=(float)rotation.Value;
        }
        Changed();
        if(sender==scale || sender==scaleX || sender==scaleY) RefreshSelection();
    }
    static Asset ReadAsset(byte[] bytes,string name,string id)
    {
        if(bytes.Length>32*1024*1024) throw new InvalidDataException("PNG demasiado grande: "+name);
        using(var stream=new MemoryStream(bytes))
        using(var image=Image.FromStream(stream,true,true))
        {
            if(image.RawFormat.Guid!=ImageFormat.Png.Guid || image.Width>8192 || image.Height>8192 ||
                (long)image.Width*image.Height>32000000) throw new InvalidDataException("PNG no válido o demasiado grande: "+name);
            var bitmap=new Bitmap(image.Width,image.Height,PixelFormat.Format32bppArgb);
            using(var graphics=Graphics.FromImage(bitmap))
            {graphics.CompositingMode=CompositingMode.SourceCopy;graphics.DrawImageUnscaled(image,0,0);}
            return new Asset {Id=id,Name=name,Png=bytes,Image=bitmap};
        }
    }
    void AddFiles(string[] files,PointF at)
    {
        if(files.Length==0) return;
        if(layers.Count+files.Length>256) throw new InvalidOperationException("El proyecto admite hasta 256 capas.");
        var pending=new List<Asset>();
        try
        {
            foreach(string file in files)
            {
                if(!Path.GetExtension(file).Equals(".png",StringComparison.OrdinalIgnoreCase)) throw new InvalidDataException("Arrastra archivos PNG.");
                pending.Add(ReadAsset(File.ReadAllBytes(file),Path.GetFileName(file),Guid.NewGuid().ToString("N")));
            }
        }
        catch {foreach(Asset asset in pending) asset.Dispose();throw;}
        for(int i=0;i<pending.Count;i++)
        {
            Asset asset=pending[i];assets.Add(asset);
            var layer=new Layer {Asset=asset,Name=Path.GetFileNameWithoutExtension(asset.Name),
                X=Math.Max(-10000,Math.Min(10000,at.X+i*24)),Y=Math.Max(-10000,Math.Min(10000,at.Y+i*24)),
                Scale=Math.Min(1,256f/Math.Max(asset.Image.Width,asset.Image.Height))};
            layers.Add(layer);SelectOnly(layer);
        }
        Changed();RefreshLists();RefreshSelection();
    }
    void PickPng()
    {
        using(var dialog=new OpenFileDialog {Filter="PNG|*.png",Multiselect=true})
            if(dialog.ShowDialog(this)==DialogResult.OK)
                try {AddFiles(dialog.FileNames,viewCenter);} catch(Exception error) {ShowError(error);}
    }
    void SelectOnly(Item item)
    {
        selection.Clear();
        if(item!=null) selection.Add(item);
    }
    Item HitItem(PointF position)
    {
        return (Item)HitMount(position) ?? HitLayer(position);
    }
    void SelectAt(PointF position,bool toggle)
    {
        Item item=HitItem(position);
        if(toggle)
        {
            if(item!=null && !selection.Remove(item)) selection.Add(item);
        }
        else if(item==null || !selection.Contains(item)) SelectOnly(item);
    }
    List<Item> OrderedSelection()
    {
        var items=new List<Item>();
        foreach(Layer layer in layers) if(selection.Contains(layer)) items.Add(layer);
        foreach(Mount mount in mounts) if(selection.Contains(mount)) items.Add(mount);
        return items;
    }
    bool CanInsert(List<Item> items)
    {
        int layerCount=items.FindAll(item => item is Layer).Count;
        return items.Count>0 && layers.Count+layerCount<=256 &&
            mounts.Count+items.Count-layerCount<=512;
    }
    void DuplicateSelected()
    {
        InsertCopies(OrderedSelection(),new PointF(24,24));
    }
    void CopySelection()
    {
        if(selection.Count==0) return;
        clipboard.Clear();
        foreach(Item item in OrderedSelection()) clipboard.Add(item.Copy());
    }
    void PasteSelection(PointF position)
    {
        if(clipboard.Count==0) return;
        InsertCopies(clipboard,Sub(position,new PointF(clipboard[0].X,clipboard[0].Y)));
    }
    void InsertCopies(List<Item> originals,PointF offset)
    {
        if(!CanInsert(originals)) return;
        var positions=Positions(originals);
        offset=BoundOffset(positions,offset);
        selection.Clear();
        foreach(Item original in originals)
        {
            Item item=original.Copy();
            item.X=ClampPosition(item.X+offset.X);
            item.Y=ClampPosition(item.Y+offset.Y);
            var layer=item as Layer;
            if(layer!=null)
            {
                Asset asset=layer.Asset;
                if(!assets.Contains(asset))
                {
                    Asset existing=assets.Find(candidate => candidate.Id==asset.Id);
                    layer.Asset=existing ?? ReadAsset(asset.Png,asset.Name,asset.Id);
                    if(existing==null) assets.Add(layer.Asset);
                }
                layer.Name+=" copia";
                layers.Add(layer);
            }
            else mounts.Add((Mount)item);
            selection.Add(item);
        }
        Changed();RefreshLists();RefreshSelection();
    }
    void RotateSelection(float degrees)
    {
        if(selection.Count==0) return;
        foreach(Item item in selection) item.Angle=NormalizeAngle(item.Angle+degrees);
        Changed();RefreshSelection();
    }
    static float ClampPosition(float value) {return Math.Max(-10000,Math.Min(10000,value));}
    static float ClampScale(float value) {return Math.Max(.01f,Math.Min(20,value));}
    static void ScaleProportionally(Layer layer,float x,float y,float factor)
    {
        factor=Math.Max(.01f/Math.Min(x,y),Math.Min(20/Math.Max(x,y),factor));
        layer.ScaleX=ClampScale(x*factor);layer.ScaleY=ClampScale(y*factor);
    }
    void DeleteSelected()
    {
        if(selection.Count==0) return;
        layers.RemoveAll(layer => selection.Contains(layer));
        mounts.RemoveAll(mount => selection.Contains(mount));
        selection.Clear();Changed();RefreshLists();RefreshSelection();
    }
    void Reorder(bool front)
    {
        List<Layer> moving=layers.FindAll(layer => selection.Contains(layer));
        if(moving.Count==0) return;
        layers.RemoveAll(layer => selection.Contains(layer));
        layers.InsertRange(front ? layers.Count : 0,moving);
        Changed();RefreshLists();RefreshSelection();
    }
    static Dictionary<Item,PointF> Positions(IEnumerable<Item> items)
    {
        var positions=new Dictionary<Item,PointF>();
        foreach(Item item in items) positions.Add(item,new PointF(item.X,item.Y));
        return positions;
    }
    static PointF BoundOffset(Dictionary<Item,PointF> positions,PointF offset)
    {
        float minX=float.NegativeInfinity,maxX=float.PositiveInfinity;
        float minY=float.NegativeInfinity,maxY=float.PositiveInfinity;
        foreach(PointF point in positions.Values)
        {
            minX=Math.Max(minX,-10000-point.X);maxX=Math.Min(maxX,10000-point.X);
            minY=Math.Max(minY,-10000-point.Y);maxY=Math.Min(maxY,10000-point.Y);
        }
        return new PointF(Math.Max(minX,Math.Min(maxX,offset.X)),Math.Max(minY,Math.Min(maxY,offset.Y)));
    }
    void MoveItems(Dictionary<Item,PointF> positions,PointF offset)
    {
        if(positions.Count==0) return;
        offset=BoundOffset(positions,offset);
        bool moved=false;
        foreach(var entry in positions)
        {
            PointF destination=Add(entry.Value,offset);
            float x=ClampPosition(destination.X),y=ClampPosition(destination.Y);
            moved |= entry.Key.X!=x || entry.Key.Y!=y;
            entry.Key.X=x;entry.Key.Y=y;
        }
        if(moved) {Changed();RefreshSelection();}
    }
    static PointF Rotate(PointF p,float degrees)
    {
        double radians=degrees*Math.PI/180,cos=Math.Cos(radians),sin=Math.Sin(radians);
        return new PointF((float)(p.X*cos-p.Y*sin),(float)(p.X*sin+p.Y*cos));
    }
    static PointF Add(PointF a,PointF b) {return new PointF(a.X+b.X,a.Y+b.Y);}
    static PointF Sub(PointF a,PointF b) {return new PointF(a.X-b.X,a.Y-b.Y);}
    PointF ToWorld(Point p)
    {
        return new PointF(viewCenter.X+(p.X-canvas.Width*.5f)/zoom,viewCenter.Y+(p.Y-canvas.Height*.5f)/zoom);
    }
    PointF ToScreen(PointF p)
    {
        return new PointF(canvas.Width*.5f+(p.X-viewCenter.X)*zoom,canvas.Height*.5f+(p.Y-viewCenter.Y)*zoom);
    }
    bool SelectionGeometry(out PointF center,out SizeF size,out float angle)
    {
        if(selectedLayer!=null)
        {
            center=new PointF(selectedLayer.X,selectedLayer.Y);angle=selectedLayer.Angle;
            size=new SizeF(selectedLayer.Asset.Image.Width*selectedLayer.ScaleX,selectedLayer.Asset.Image.Height*selectedLayer.ScaleY);return true;
        }
        if(selectedMount!=null)
        {
            center=new PointF(selectedMount.X,selectedMount.Y);size=MountSize(selectedMount.Kind);angle=selectedMount.Angle;return true;
        }
        center=PointF.Empty;size=SizeF.Empty;angle=0;return false;
    }
    PointF[] SelectionCorners()
    {
        PointF center;SizeF size;float angle;
        if(!SelectionGeometry(out center,out size,out angle)) return new PointF[0];
        return new[] {
            ToScreen(Add(center,Rotate(new PointF(-size.Width/2,-size.Height/2),angle))),
            ToScreen(Add(center,Rotate(new PointF(size.Width/2,-size.Height/2),angle))),
            ToScreen(Add(center,Rotate(new PointF(size.Width/2,size.Height/2),angle))),
            ToScreen(Add(center,Rotate(new PointF(-size.Width/2,size.Height/2),angle)))};
    }
    PointF RotationHandle()
    {
        PointF center;SizeF size;float angle;
        if(!SelectionGeometry(out center,out size,out angle)) return PointF.Empty;
        return ToScreen(Add(center,Rotate(new PointF(0,-size.Height/2-30/zoom),angle)));
    }
    static PointF EdgeMidpoint(PointF[] corners,int edge)
    {
        PointF a=corners[edge],b=corners[(edge+1)%4];
        return new PointF((a.X+b.X)/2,(a.Y+b.Y)/2);
    }
    static float Distance(PointF a,PointF b)
    {
        float x=a.X-b.X,y=a.Y-b.Y;return (float)Math.Sqrt(x*x+y*y);
    }
    static float PointerAngle(PointF point,PointF center)
    {
        return (float)(Math.Atan2(point.Y-center.Y,point.X-center.X)*180/Math.PI);
    }
    static float NormalizeAngle(float angle)
    {
        while(angle>180) angle-=360;while(angle<-180) angle+=360;return angle;
    }
    bool BeginTransform(Point pointer)
    {
        PointF center;SizeF size;float angle;
        if(!SelectionGeometry(out center,out size,out angle)) return false;
        rotating=Distance(pointer,RotationHandle())<=11;
        stretchAxis=0;
        if(!rotating && selectedLayer!=null)
        {
            PointF[] corners=SelectionCorners();
            foreach(PointF corner in corners) if(Distance(pointer,corner)<=8) {scaling=true;break;}
            if(!scaling)
                for(int edge=0;edge<4;edge++)
                    if(Distance(pointer,EdgeMidpoint(corners,edge))<=8)
                    {
                        stretchAxis=edge%2==0 ? 2 : 1;
                        stretchSide=edge==0 || edge==3 ? -1 : 1;
                        break;
                    }
        }
        if(!rotating && !scaling && stretchAxis==0) return false;
        transformCenter=center;transformStartAngle=angle;
        transformStartPointer=PointerAngle(ToWorld(pointer),center);
        transformStartRadius=Math.Max(.01f,Distance(ToWorld(pointer),center));
        if(selectedLayer!=null) {startScaleX=selectedLayer.ScaleX;startScaleY=selectedLayer.ScaleY;}
        canvas.Capture=true;return true;
    }
    void DrawSelectionControls(Graphics g)
    {
        PointF center;SizeF size;float angle;
        if(!SelectionGeometry(out center,out size,out angle)) return;
        PointF[] corners=SelectionCorners();PointF handle=RotationHandle();
        var state=g.Save();g.SmoothingMode=SmoothingMode.AntiAlias;
        using(var pen=new Pen(Color.Gold,1.5f))
        {
            g.DrawPolygon(pen,corners);
            g.DrawLine(pen,new PointF((corners[0].X+corners[1].X)/2,(corners[0].Y+corners[1].Y)/2),handle);
            if(selectedLayer!=null) foreach(PointF corner in corners)
            {
                g.FillRectangle(Brushes.Gold,corner.X-5,corner.Y-5,10,10);
                g.DrawRectangle(Pens.Black,corner.X-5,corner.Y-5,10,10);
            }
            if(selectedLayer!=null)
                for(int edge=0;edge<4;edge++)
                {
                    PointF middle=EdgeMidpoint(corners,edge);
                    PointF[] diamond={new PointF(middle.X,middle.Y-6),new PointF(middle.X+6,middle.Y),
                        new PointF(middle.X,middle.Y+6),new PointF(middle.X-6,middle.Y)};
                    g.FillPolygon(Brushes.Turquoise,diamond);
                    g.DrawPolygon(Pens.Black,diamond);
                }
            g.FillEllipse(Brushes.Gold,handle.X-7,handle.Y-7,14,14);
            g.DrawEllipse(Pens.Black,handle.X-7,handle.Y-7,14,14);
        }
        float left=float.MaxValue,bottom=float.MinValue;
        foreach(PointF corner in corners) {left=Math.Min(left,corner.X);bottom=Math.Max(bottom,corner.Y);}
        string caption=selectedLayer!=null ? Math.Round(size.Width)+" × "+Math.Round(size.Height)+" px · X "+Math.Round(selectedLayer.ScaleX*100,1)+" % · Y "+Math.Round(selectedLayer.ScaleY*100,1)+" % · " : "";
        caption+=Math.Round(angle,1)+"°";
        SizeF labelSize=g.MeasureString(caption,Font);
        float x=Math.Max(4,Math.Min(canvas.Width-labelSize.Width-8,left));
        float y=Math.Max(28,Math.Min(canvas.Height-labelSize.Height-6,bottom+9));
        using(var background=new SolidBrush(Color.FromArgb(225,12,20,34))) g.FillRectangle(background,x-3,y-2,labelSize.Width+6,labelSize.Height+4);
        g.DrawString(caption,Font,Brushes.Gold,x,y);g.Restore(state);
    }
    Layer HitLayer(PointF point)
    {
        for(int i=layers.Count-1;i>=0;i--)
        {
            Layer layer=layers[i];PointF local=Rotate(Sub(point,new PointF(layer.X,layer.Y)),-layer.Angle);

            int x=(int)Math.Floor(local.X/layer.ScaleX+layer.Asset.Image.Width*.5f);
            int y=(int)Math.Floor(local.Y/layer.ScaleY+layer.Asset.Image.Height*.5f);
            if(x>=0 && y>=0 && x<layer.Asset.Image.Width && y<layer.Asset.Image.Height && layer.Asset.Image.GetPixel(x,y).A>12) return layer;
        }
        return null;
    }
    static SizeF MountSize(string kind)
    {
        return kind=="normal" ? new SizeF(NormalLength,NormalWidth) : kind=="dread" ? new SizeF(DreadLength,DreadWidth) : new SizeF(20,20);
    }
    Mount HitMount(PointF point)
    {
        for(int i=mounts.Count-1;i>=0;i--)
        {
            Mount mount=mounts[i];SizeF size=MountSize(mount.Kind);
            PointF local=Rotate(Sub(point,new PointF(mount.X,mount.Y)),-mount.Angle);
            if(Math.Abs(local.X)<=size.Width/2+4/zoom && Math.Abs(local.Y)<=size.Height/2+4/zoom) return mount;
        }
        return null;
    }
    void CanvasDown(object sender,MouseEventArgs e)
    {
        canvas.Focus();mouseStart=e.Location;worldStart=ToWorld(e.Location);
        if(e.Button==MouseButtons.Middle) {panning=true;panStart=viewCenter;canvas.Capture=true;return;}
        if(e.Button==MouseButtons.Right)
        {
            rightPending=true;panStart=viewCenter;canvas.Capture=true;return;
        }
        if(e.Button!=MouseButtons.Left) return;
        if(mode.SelectedIndex==0 && (ModifierKeys & Keys.Control)!=0)
        {
            SelectAt(worldStart,true);RefreshSelection();return;
        }
        if(mode.SelectedIndex==0 && BeginTransform(e.Location)) return;
        if(mode.SelectedIndex==4)
        {
            origin=new PointF(Math.Max(-10000,Math.Min(10000,worldStart.X)),Math.Max(-10000,Math.Min(10000,worldStart.Y)));
            mode.SelectedIndex=0;Changed();return;
        }
        if(mode.SelectedIndex>=1 && mode.SelectedIndex<=3)
        {
            if(mounts.Count>=512) {ShowError(new InvalidOperationException("Límite de 512 hardpoints."));return;}
            var mount=new Mount {Kind=mode.SelectedIndex==1 ? "normal" : mode.SelectedIndex==2 ? "dread" : "pdc",
                X=Math.Max(-10000,Math.Min(10000,worldStart.X)),Y=Math.Max(-10000,Math.Min(10000,worldStart.Y))};
            mounts.Add(mount);SelectOnly(mount);mode.SelectedIndex=0;Changed();RefreshLists();
        }
        else SelectAt(worldStart,false);
        RefreshSelection();
        if(selection.Count>0)
        {
            dragOrigins=Positions(selection);
            dragging=true;canvas.Capture=true;
        }
    }
    void CanvasMove(object sender,MouseEventArgs e)
    {
        if(rightPending && !panning && Distance(e.Location,mouseStart)>=5) panning=true;
        if(panning)
        {
            viewCenter=new PointF(panStart.X-(e.X-mouseStart.X)/zoom,panStart.Y-(e.Y-mouseStart.Y)/zoom);canvas.Invalidate();return;
        }
        if(scaling || rotating || stretchAxis!=0)
        {
            PointF pointer=ToWorld(e.Location);
            if(scaling && selectedLayer!=null)
                ScaleProportionally(selectedLayer,startScaleX,startScaleY,Distance(pointer,transformCenter)/transformStartRadius);
            if(stretchAxis!=0 && selectedLayer!=null)
            {
                PointF delta=Rotate(Sub(pointer,worldStart),-transformStartAngle);
                if(stretchAxis==1)
                    selectedLayer.ScaleX=ClampScale(startScaleX+2*stretchSide*delta.X/selectedLayer.Asset.Image.Width);
                else
                    selectedLayer.ScaleY=ClampScale(startScaleY+2*stretchSide*delta.Y/selectedLayer.Asset.Image.Height);
            }
            if(rotating)
            {
                float angle=NormalizeAngle(transformStartAngle+PointerAngle(pointer,transformCenter)-transformStartPointer);
                if(selectedLayer!=null) selectedLayer.Angle=angle;
                else if(selectedMount!=null) selectedMount.Angle=angle;
            }
            Changed();RefreshSelection();return;
        }
        if(!dragging) return;
        MoveItems(dragOrigins,Sub(ToWorld(e.Location),worldStart));
    }
    void CanvasUp(object sender,MouseEventArgs e)
    {
        bool showMenu=e.Button==MouseButtons.Right && rightPending && !panning && Distance(e.Location,mouseStart)<5;
        dragging=panning=rightPending=scaling=rotating=false;stretchAxis=0;canvas.Capture=false;
        if(showMenu)
        {
            pastePosition=ToWorld(e.Location);SelectAt(pastePosition,false);
            RefreshSelection();selectionMenu.Items[0].Enabled=selection.Count>0;
            selectionMenu.Items[1].Enabled=selectionMenu.Items[2].Enabled=frontButton.Enabled;
            bool hasSelection=selection.Count>0;
            selectionMenu.Items[4].Enabled=selectionMenu.Items[7].Enabled=selectionMenu.Items[8].Enabled=hasSelection;
            selectionMenu.Items[5].Enabled=CanInsert(clipboard);
            selectionMenu.Items[6].Enabled=duplicateButton.Enabled;
            selectionMenu.Show(canvas,e.Location);
        }
    }
    void CanvasWheel(object sender,MouseEventArgs e)
    {
        PointF before=ToWorld(e.Location);
        zoom=(float)Math.Max(.05,Math.Min(8,zoom*Math.Pow(1.12,e.Delta/120.0)));
        viewCenter=Add(viewCenter,Sub(before,ToWorld(e.Location)));canvas.Invalidate();UpdateStatus();
    }
    static RectangleF LayerBounds(Layer layer)
    {
        float w=layer.Asset.Image.Width*layer.ScaleX/2,h=layer.Asset.Image.Height*layer.ScaleY/2;
        float left=float.MaxValue,top=float.MaxValue,right=float.MinValue,bottom=float.MinValue;
        foreach(PointF corner in new[] {new PointF(-w,-h),new PointF(w,-h),new PointF(w,h),new PointF(-w,h)})
        {
            PointF p=Add(Rotate(corner,layer.Angle),new PointF(layer.X,layer.Y));
            left=Math.Min(left,p.X);right=Math.Max(right,p.X);top=Math.Min(top,p.Y);bottom=Math.Max(bottom,p.Y);
        }
        return RectangleF.FromLTRB(left,top,right,bottom);
    }
    void FitView()
    {
        if(layers.Count==0) {viewCenter=origin;zoom=1;}
        else
        {
            RectangleF bounds=LayerBounds(layers[0]);
            foreach(Layer layer in layers) bounds=RectangleF.Union(bounds,LayerBounds(layer));
            viewCenter=new PointF(bounds.X+bounds.Width/2,bounds.Y+bounds.Height/2);
            zoom=Math.Max(.05f,Math.Min(4,Math.Min((canvas.Width-70)/Math.Max(1,bounds.Width),(canvas.Height-70)/Math.Max(1,bounds.Height))));
        }
        canvas.Invalidate();UpdateStatus();
    }
    void DrawLayers(Graphics g)
    {
        foreach(Layer layer in layers)
        {
            var state=g.Save();g.TranslateTransform(layer.X,layer.Y);g.RotateTransform(layer.Angle);g.ScaleTransform(layer.ScaleX,layer.ScaleY);
            g.DrawImage(layer.Asset.Image,-layer.Asset.Image.Width/2f,-layer.Asset.Image.Height/2f,layer.Asset.Image.Width,layer.Asset.Image.Height);
            g.Restore(state);
        }
    }
    void PaintCanvas(object sender,PaintEventArgs e)
    {

        Graphics g=e.Graphics;g.InterpolationMode=InterpolationMode.NearestNeighbor;g.PixelOffsetMode=PixelOffsetMode.Half;
        g.TranslateTransform(canvas.Width*.5f,canvas.Height*.5f);g.ScaleTransform(zoom,zoom);g.TranslateTransform(-viewCenter.X,-viewCenter.Y);
        PointF start=ToWorld(Point.Empty),end=ToWorld(new Point(canvas.Width,canvas.Height));
        float grid=zoom<.2f ? 256 : zoom<.5f ? 128 : 32;
        using(var pen=new Pen(Color.FromArgb(29,42,61),1/zoom))
        {
            for(float x=(float)Math.Floor(start.X/grid)*grid;x<end.X;x+=grid) g.DrawLine(pen,x,start.Y,x,end.Y);
            for(float y=(float)Math.Floor(start.Y/grid)*grid;y<end.Y;y+=grid) g.DrawLine(pen,start.X,y,end.X,y);
        }
        DrawLayers(g);
        foreach(Mount mount in mounts)
        {
            var state=g.Save();g.TranslateTransform(mount.X,mount.Y);g.RotateTransform(mount.Angle);
            SizeF size=MountSize(mount.Kind);
            Color color=mount.Kind=="normal" ? Color.PaleGreen : mount.Kind=="dread" ? Color.Turquoise : Color.Orange;
            using(var pen=new Pen(selection.Contains(mount) ? Color.Gold : color,1.5f/zoom))
            using(var fill=new SolidBrush(Color.FromArgb(65,color)))
            {
                if(mount.Kind=="pdc") {g.FillEllipse(fill,-10,-10,20,20);g.DrawEllipse(pen,-10,-10,20,20);}
                else {g.FillRectangle(fill,-size.Width/2,-size.Height/2,size.Width,size.Height);g.DrawRectangle(pen,-size.Width/2,-size.Height/2,size.Width,size.Height);}
                g.DrawLine(pen,0,0,size.Width/2+15,0);g.DrawLine(pen,size.Width/2+15,0,size.Width/2+7,-5);g.DrawLine(pen,size.Width/2+15,0,size.Width/2+7,5);
            }
            g.Restore(state);
        }
        using(var pen=new Pen(Color.HotPink,1.5f/zoom))
        {
            float radius=10/zoom;g.DrawLine(pen,origin.X-radius,origin.Y,origin.X+radius,origin.Y);
            g.DrawLine(pen,origin.X,origin.Y-radius,origin.X,origin.Y+radius);
        }
        if(selection.Count>1)
        {
            using(var outline=new Pen(Color.Gold,1.5f/zoom))
                foreach(Layer layer in layers)
                {
                    if(!selection.Contains(layer)) continue;
                    var state=g.Save();
                    g.TranslateTransform(layer.X,layer.Y);g.RotateTransform(layer.Angle);
                    float width=layer.Asset.Image.Width*layer.ScaleX,height=layer.Asset.Image.Height*layer.ScaleY;
                    g.DrawRectangle(outline,-width/2,-height/2,width,height);
                    g.Restore(state);
                }
        }
        g.ResetTransform();DrawSelectionControls(g);g.DrawString("Origen de la estación",Font,Brushes.HotPink,10,10);
        if(layers.Count==0) g.DrawString("Arrastra aquí tus PNG para empezar",Font,Brushes.LightSteelBlue,30,50);
    }
    int ExportSize(bool enforceLimit=true)
    {
        if(layers.Count==0 && enforceLimit) throw new InvalidOperationException("Añade al menos un PNG.");
        float radius=0;
        foreach(Layer layer in layers)
        {
            RectangleF b=LayerBounds(layer);
            radius=Math.Max(radius,Math.Max(Math.Max(Math.Abs(b.Left-origin.X),Math.Abs(b.Right-origin.X)),Math.Max(Math.Abs(b.Top-origin.Y),Math.Abs(b.Bottom-origin.Y))));
        }
        int side=Math.Max(32,(int)Math.Ceiling(radius+16)*2);
        if(enforceLimit && side>MaxExportSize) throw new InvalidOperationException("La estación supera 4096 × 4096. Reduce la escala o acerca las piezas al origen.");
        return side;
    }
    StationDesign CaptureDesign(int side)
    {
        var design=new StationDesign {Version=2,OriginX=origin.X,OriginY=origin.Y,ExportSize=side,ExportOriginX=side/2f,ExportOriginY=side/2f};
        foreach(Asset asset in assets)
            if(layers.Exists(layer => layer.Asset==asset)) design.Assets.Add(new DesignAsset {Id=asset.Id,Name=asset.Name,Png=Convert.ToBase64String(asset.Png)});
        foreach(Layer layer in layers) design.Layers.Add(new DesignLayer {Asset=layer.Asset.Id,Name=layer.Name,X=layer.X,Y=layer.Y,Angle=layer.Angle,Scale=layer.Scale,ScaleX=layer.ScaleX,ScaleY=layer.ScaleY});
        foreach(Mount mount in mounts) design.Hardpoints.Add(new DesignPoint {Kind=mount.Kind,X=mount.X,Y=mount.Y,Angle=mount.Angle});
        return design;
    }
    byte[] RenderPng(int side)
    {
        using(var image=new Bitmap(side,side,PixelFormat.Format32bppArgb))
        using(var g=Graphics.FromImage(image))
        using(var stream=new MemoryStream())
        {
            g.Clear(Color.Transparent);g.InterpolationMode=InterpolationMode.NearestNeighbor;g.PixelOffsetMode=PixelOffsetMode.Half;
            g.TranslateTransform(side/2f-origin.X,side/2f-origin.Y);DrawLayers(g);image.Save(stream,ImageFormat.Png);return stream.ToArray();
        }
    }
    static byte[] Serialize(StationDesign design)
    {
        using(var stream=new MemoryStream()) {new DataContractJsonSerializer(typeof(StationDesign)).WriteObject(stream,design);return stream.ToArray();}
    }
    byte[] HardpointCsv()
    {
        var text=new StringBuilder("entidad,id,tipo,indice,x,y,rotacion_grados,longitud,anchura\n");
        int normal=0,dread=0,pdc=0;
        foreach(Mount mount in mounts)
        {
            SizeF size=MountSize(mount.Kind);

            int index=mount.Kind=="normal" ? normal++ : mount.Kind=="dread" ? dread++ : pdc++;
            string kind=mount.Kind=="pdc" ? "pdc" : mount.Kind=="dread" ? "atraque_dread" : "atraque_normal";
            text.AppendFormat(Numbers,"estacion,*,{0},{1},{2:R},{3:R},{4:R},{5:R},{6:R}\n",kind,index,mount.X-origin.X,mount.Y-origin.Y,mount.Angle,size.Width,size.Height);
        }
        return new UTF8Encoding(true).GetBytes(text.ToString());
    }
    static void CommitFiles(List<OutputFile> files,List<byte[]> contents)
    {
        string token=Guid.NewGuid().ToString("N");
        try
        {
            for(int i=0;i<files.Count;i++)
            {
                files[i].Temporary=files[i].Path+"."+token+".tmp";files[i].Backup=files[i].Path+"."+token+".bak";
                File.WriteAllBytes(files[i].Temporary,contents[i]);
            }
            foreach(OutputFile file in files)
            {
                if(File.Exists(file.Path)) File.Move(file.Path,file.Backup);
                File.Move(file.Temporary,file.Path);file.Installed=true;
            }
        }
        catch
        {
            for(int i=files.Count-1;i>=0;i--)
            {
                OutputFile file=files[i];if(file.Installed && File.Exists(file.Path)) File.Delete(file.Path);
                if(file.Backup!=null && File.Exists(file.Backup)) File.Move(file.Backup,file.Path);
            }
            throw;
        }
        finally {foreach(OutputFile file in files) if(file.Temporary!=null && File.Exists(file.Temporary)) File.Delete(file.Temporary);}
        foreach(OutputFile file in files) if(File.Exists(file.Backup)) File.Delete(file.Backup);
    }
    void ExportTo(string path)
    {
        int side=ExportSize();string stem=Path.Combine(Path.GetDirectoryName(path),Path.GetFileNameWithoutExtension(path));
        var paths=new List<OutputFile> {new OutputFile {Path=stem+".png"},new OutputFile {Path=stem+".hardpoints.csv"}};
        CommitFiles(paths,new List<byte[]> {RenderPng(side),HardpointCsv()});
        exportPath=stem+".png";
        status.Text="Exportados PNG transparente y ficha .hardpoints.csv · "+side+" × "+side+" px";
    }
    void SaveProjectTo(string path)
    {
        byte[] data=Serialize(CaptureDesign(ExportSize(false)));
        if(data.Length>128*1024*1024) throw new InvalidOperationException("Proyecto demasiado grande.");
        CommitFiles(new List<OutputFile> {new OutputFile {Path=path}},new List<byte[]> {data});
        projectPath=path;dirty=false;UpdateStatus();
    }
    void SaveProject()
    {
        using(var dialog=new SaveFileDialog {Filter="Proyecto de estación|*.station.json",AddExtension=false,
            FileName=projectPath==null ? "estacion.station.json" : Path.GetFileName(projectPath)})
        {
            if(projectPath!=null) dialog.InitialDirectory=Path.GetDirectoryName(projectPath);
            dialog.OverwritePrompt=false;
            if(dialog.ShowDialog(this)!=DialogResult.OK) return;
            string path=dialog.FileName;
            if(!path.EndsWith(".station.json",StringComparison.OrdinalIgnoreCase)) path+=".station.json";
            if(File.Exists(path) && MessageBox.Show(this,"¿Sustituir el proyecto guardado?","Guardar proyecto",
                MessageBoxButtons.YesNo,MessageBoxIcon.Question)!=DialogResult.Yes) return;
            try {SaveProjectTo(path);} catch(Exception error) {ShowError(error);}
        }
    }
    void SaveDesign()
    {
        using(var dialog=new SaveFileDialog {Filter="Estación PNG|*.png",DefaultExt="png",AddExtension=true,FileName=exportPath==null ? "estacion.png" : Path.GetFileName(exportPath)})
        {
            if(exportPath!=null) dialog.InitialDirectory=Path.GetDirectoryName(exportPath);
            if(dialog.ShowDialog(this)!=DialogResult.OK) return;
            string stem=Path.Combine(Path.GetDirectoryName(dialog.FileName),Path.GetFileNameWithoutExtension(dialog.FileName));
            if(File.Exists(stem+".hardpoints.csv") &&
                MessageBox.Show(this,"Se sustituirá la ficha de hardpoints. ¿Continuar?","Exportar estación",
                    MessageBoxButtons.YesNo,MessageBoxIcon.Question)!=DialogResult.Yes) return;
            try {ExportTo(dialog.FileName);} catch(Exception error) {ShowError(error);}
        }
    }
    static bool Finite(float number) {return !float.IsNaN(number) && !float.IsInfinity(number);}
    static void ValidatePoint(float x,float y,float angle)
    {
        if(!Finite(x) || !Finite(y) || !Finite(angle) || Math.Abs(x)>10000 || Math.Abs(y)>10000 || Math.Abs(angle)>360)
            throw new InvalidDataException("Coordenadas o ángulos fuera de rango.");
    }
    void LoadDesign(string path)
    {
        if(new FileInfo(path).Length>128*1024*1024) throw new InvalidDataException("Proyecto demasiado grande.");
        StationDesign design;
        using(var stream=File.OpenRead(path)) design=(StationDesign)new DataContractJsonSerializer(typeof(StationDesign)).ReadObject(stream);
        if(design==null || (design.Version!=1 && design.Version!=2) || design.Assets==null || design.Layers==null || design.Hardpoints==null ||
            design.Assets.Count>256 || design.Layers.Count>256 || design.Hardpoints.Count>512) throw new InvalidDataException("Formato de proyecto no válido.");
        ValidatePoint(design.OriginX,design.OriginY,0);
        var loadedAssets=new List<Asset>();var loadedLayers=new List<Layer>();var loadedMounts=new List<Mount>();
        try
        {
            var lookup=new Dictionary<string,Asset>();
            foreach(DesignAsset data in design.Assets)
            {
                if(data==null || string.IsNullOrEmpty(data.Id) || lookup.ContainsKey(data.Id)) throw new InvalidDataException("ID de imagen no válido.");
                Asset asset=ReadAsset(Convert.FromBase64String(data.Png),data.Name,data.Id);loadedAssets.Add(asset);lookup.Add(asset.Id,asset);
            }
            foreach(DesignLayer data in design.Layers)
            {
                if(data==null) throw new InvalidDataException("Capa no válida.");

                ValidatePoint(data.X,data.Y,data.Angle);
                float x=data.ScaleX ?? data.Scale,y=data.ScaleY ?? data.Scale;
                if(!Finite(x) || !Finite(y) || x<.01f || x>20 || y<.01f || y>20 || data.Asset==null || !lookup.ContainsKey(data.Asset))
                    throw new InvalidDataException("Escala o recurso de capa no válido.");
                loadedLayers.Add(new Layer {Asset=lookup[data.Asset],Name=data.Name ?? "Capa",X=data.X,Y=data.Y,Angle=data.Angle,ScaleX=x,ScaleY=y});
            }
            foreach(DesignPoint data in design.Hardpoints)
            {
                if(data==null || (data.Kind!="normal" && data.Kind!="dread" && data.Kind!="pdc")) throw new InvalidDataException("Hardpoint no válido.");
                ValidatePoint(data.X,data.Y,data.Angle);loadedMounts.Add(new Mount {Kind=data.Kind,X=data.X,Y=data.Y,Angle=data.Angle});
            }
        }
        catch {foreach(Asset asset in loadedAssets) asset.Dispose();throw;}
        ClearDesign();assets.AddRange(loadedAssets);layers.AddRange(loadedLayers);mounts.AddRange(loadedMounts);
        origin=new PointF(design.OriginX,design.OriginY);
        string suffix=".station.json";exportPath=path.EndsWith(suffix,StringComparison.OrdinalIgnoreCase) ? path.Substring(0,path.Length-suffix.Length)+".png" : null;
        projectPath=path;
        dirty=false;RefreshLists();RefreshSelection();FitView();
    }
    bool ConfirmDiscard()
    {
        if(!dirty) return true;
        var result=MessageBox.Show(this,"Hay cambios pendientes. ¿Guardar el proyecto antes de continuar?","stationBuilder",MessageBoxButtons.YesNoCancel,MessageBoxIcon.Question);
        if(result==DialogResult.Cancel) return false;
        if(result==DialogResult.Yes) {SaveProject();return !dirty;}
        return true;
    }
    void ClearDesign()
    {
        foreach(Asset asset in assets) asset.Dispose();
        assets.Clear();layers.Clear();mounts.Clear();selection.Clear();
        origin=viewCenter=PointF.Empty;zoom=1;exportPath=projectPath=null;dirty=false;
    }
    void NewDesign() {if(!ConfirmDiscard()) return;ClearDesign();RefreshLists();RefreshSelection();canvas.Invalidate();}
    void OpenDesign()
    {
        if(!ConfirmDiscard()) return;
        using(var dialog=new OpenFileDialog {Filter="Proyecto de estación|*.station.json"})
            if(dialog.ShowDialog(this)==DialogResult.OK)
                try {LoadDesign(dialog.FileName);} catch(Exception error) {ShowError(error);}
    }
    protected override bool ProcessCmdKey(ref Message message,Keys keyData)
    {
        if(keyData==(Keys.Control|Keys.S)) {SaveProject();return true;}
        if(keyData==(Keys.Control|Keys.O)) {OpenDesign();return true;}
        if(ActiveControl is TextBoxBase || ActiveControl is NumericUpDown || ActiveControl is ComboBox)
            return base.ProcessCmdKey(ref message,keyData);

        switch(keyData)
        {
            case Keys.Control|Keys.C:
                if(selection.Count>0) {CopySelection();return true;}
                break;
            case Keys.Control|Keys.V:
                if(clipboard.Count>0)
                {
                    PasteSelection(new PointF(clipboard[0].X+24,clipboard[0].Y+24));
                    return true;
                }
                break;
            case Keys.Control|Keys.D: DuplicateSelected();return true;
            case Keys.Delete: DeleteSelected();return true;
            case Keys.Escape: selection.Clear();mode.SelectedIndex=0;RefreshSelection();return true;
            case Keys.Left: case Keys.Right: case Keys.Up: case Keys.Down:
                if(selection.Count>0)
                {
                    float x=keyData==Keys.Left ? -1 : keyData==Keys.Right ? 1 : 0;
                    float y=keyData==Keys.Up ? -1 : keyData==Keys.Down ? 1 : 0;
                    MoveItems(Positions(selection),new PointF(x,y));
                    return true;
                }
                break;
        }
        return base.ProcessCmdKey(ref message,keyData);
    }
    protected override void Dispose(bool disposing)
    {
        if(disposing) {selectionMenu.Dispose();foreach(Asset asset in assets) asset.Dispose();}
        base.Dispose(disposing);
    }
    static void Require(bool condition,string message) {if(!condition) throw new InvalidOperationException(message);}
    static void InteractionSmoke(StationBuilder editor)
    {
        editor.zoom=1;editor.viewCenter=PointF.Empty;editor.mounts.Clear();editor.selection.Clear();
        Layer layer=editor.layers[editor.layers.Count-1];editor.SelectOnly(layer);
        layer.X=layer.Y=layer.Angle=0;layer.Scale=4;editor.RefreshSelection();
        Point corner=Point.Round(editor.SelectionCorners()[2]);Point center=Point.Round(editor.ToScreen(PointF.Empty));
        editor.CanvasDown(editor.canvas,new MouseEventArgs(MouseButtons.Left,1,corner.X,corner.Y,0));
        editor.CanvasMove(editor.canvas,new MouseEventArgs(MouseButtons.Left,0,center.X+(corner.X-center.X)*2,center.Y+(corner.Y-center.Y)*2,0));
        editor.CanvasUp(editor.canvas,new MouseEventArgs(MouseButtons.Left,1,0,0,0));
        Require(Math.Abs(layer.Scale-8)<.1f,"Escala por esquina");
        Point handle=Point.Round(editor.RotationHandle());int radius=center.Y-handle.Y;
        editor.CanvasDown(editor.canvas,new MouseEventArgs(MouseButtons.Left,1,handle.X,handle.Y,0));
        editor.CanvasMove(editor.canvas,new MouseEventArgs(MouseButtons.Left,0,center.X+radius,center.Y,0));
        editor.CanvasUp(editor.canvas,new MouseEventArgs(MouseButtons.Left,1,0,0,0));
        Require(Math.Abs(layer.Angle-90)<1,"Giro directo de PNG");
        Point edge=Point.Round(EdgeMidpoint(editor.SelectionCorners(),1));
        editor.CanvasDown(editor.canvas,new MouseEventArgs(MouseButtons.Left,1,edge.X,edge.Y,0));
        editor.CanvasMove(editor.canvas,new MouseEventArgs(MouseButtons.Left,0,edge.X,edge.Y+20,0));
        editor.CanvasUp(editor.canvas,new MouseEventArgs(MouseButtons.Left,1,edge.X,edge.Y+20,0));
        Require(Math.Abs(layer.ScaleX-9)<.1f && Math.Abs(layer.ScaleY-8)<.1f,"Escala X local en PNG girado");
        edge=Point.Round(EdgeMidpoint(editor.SelectionCorners(),2));
        editor.CanvasDown(editor.canvas,new MouseEventArgs(MouseButtons.Left,1,edge.X,edge.Y,0));
        editor.CanvasMove(editor.canvas,new MouseEventArgs(MouseButtons.Left,0,edge.X-20,edge.Y,0));
        editor.CanvasUp(editor.canvas,new MouseEventArgs(MouseButtons.Left,1,edge.X-20,edge.Y,0));
        Require(Math.Abs(layer.ScaleX-9)<.1f && Math.Abs(layer.ScaleY-10)<.1f,"Escala Y local en PNG girado");
        foreach(string kind in new[] {"normal","dread","pdc"})
        {
            var mount=new Mount {Kind=kind,X=200,Y=100};editor.mounts.Add(mount);
            editor.SelectOnly(mount);editor.RefreshSelection();
            center=Point.Round(editor.ToScreen(new PointF(200,100)));handle=Point.Round(editor.RotationHandle());radius=center.Y-handle.Y;
            editor.CanvasDown(editor.canvas,new MouseEventArgs(MouseButtons.Left,1,handle.X,handle.Y,0));
            editor.CanvasMove(editor.canvas,new MouseEventArgs(MouseButtons.Left,0,center.X+radius,center.Y,0));
            editor.CanvasUp(editor.canvas,new MouseEventArgs(MouseButtons.Left,1,0,0,0));
            Require(Math.Abs(mount.Angle-90)<1,"Giro directo de "+kind);
        }
        editor.mounts.Clear();editor.selection.Clear();editor.SelectOnly(layer);layer.Angle=0;
        center=Point.Round(editor.ToScreen(PointF.Empty));
        editor.CanvasDown(editor.canvas,new MouseEventArgs(MouseButtons.Right,1,center.X,center.Y,0));
        editor.CanvasMove(editor.canvas,new MouseEventArgs(MouseButtons.Right,0,center.X+50,center.Y+30,0));
        editor.CanvasUp(editor.canvas,new MouseEventArgs(MouseButtons.Right,1,center.X+50,center.Y+30,0));
        PointF movedView=editor.viewCenter;
        Require(movedView.X==-50 && movedView.Y==-30 && layer.X==0 && layer.Y==0 && !editor.selectionMenu.Visible,"Arrastre derecho del plano sin menú ni movimiento de pieza");
        center=Point.Round(editor.ToScreen(PointF.Empty));
        editor.CanvasDown(editor.canvas,new MouseEventArgs(MouseButtons.Right,1,center.X,center.Y,0));
        editor.CanvasUp(editor.canvas,new MouseEventArgs(MouseButtons.Right,1,center.X,center.Y,0));
        Require(editor.selectionMenu.Visible && editor.selectedLayer==layer,"Menú de clic derecho");
        editor.selectionMenu.Items[4].PerformClick();
        editor.selectionMenu.Items[7].PerformClick();
        Require(layer.Angle==-90,"Giro izquierdo desde el menú");
        editor.selectionMenu.Items[8].PerformClick();
        Require(layer.Angle==0,"Giro derecho desde el menú");
        ((ToolStripMenuItem)editor.selectionMenu.Items[2]).PerformClick();
        Require(editor.layers[0]==layer,"Menú enviar al fondo");
        ((ToolStripMenuItem)editor.selectionMenu.Items[1]).PerformClick();
        Require(editor.layers[editor.layers.Count-1]==layer,"Menú traer al frente");
        int count=editor.layers.Count;((ToolStripMenuItem)editor.selectionMenu.Items[0]).PerformClick();
        Require(editor.layers.Count==count-1,"Menú eliminar");editor.selectionMenu.Close();
        Point destination=Point.Round(editor.ToScreen(new PointF(300,-100)));
        editor.CanvasDown(editor.canvas,new MouseEventArgs(MouseButtons.Right,1,destination.X,destination.Y,0));
        editor.CanvasUp(editor.canvas,new MouseEventArgs(MouseButtons.Right,1,destination.X,destination.Y,0));
        editor.selectionMenu.Items[5].PerformClick();
        Require(editor.layers.Count==count && Math.Abs(editor.selectedLayer.X-300)<1 &&
            editor.selectedLayer.ScaleX==layer.ScaleX && editor.selectedLayer.Angle==0,"Pegar aquí conserva la copia original");
        editor.selectionMenu.Close();
        editor.CanvasDown(editor.canvas,new MouseEventArgs(MouseButtons.Right,1,destination.X,destination.Y,0));
        editor.CanvasUp(editor.canvas,new MouseEventArgs(MouseButtons.Right,1,destination.X,destination.Y,0));
        editor.selectionMenu.Items[6].PerformClick();
        Require(editor.layers.Count==count+1 && editor.selectedLayer.ScaleY==layer.ScaleY,"Duplicar conserva la deformación");
        editor.selectionMenu.Close();

        Layer groupLayer=editor.selectedLayer;
        groupLayer.X=0;groupLayer.Y=0;groupLayer.Angle=0;groupLayer.Scale=1;
        var groupMount=new Mount {Kind="pdc",X=60,Y=10};
        editor.mounts.Add(groupMount);
        editor.SelectAt(new PointF(60,10),true);
        Require(editor.selection.Count==2,"Selección mixta con Ctrl");
        editor.SelectAt(new PointF(60,10),true);
        Require(editor.selection.Count==1 && editor.selectedLayer==groupLayer,"Ctrl retira un elemento seleccionado");
        editor.SelectAt(new PointF(60,10),true);
        editor.RefreshLists();editor.RefreshSelection();
        editor.canvas.Focus();
        var message=new Message();
        Require(editor.ProcessCmdKey(ref message,Keys.Right),"Flecha interceptada en el lienzo");
        editor.ProcessCmdKey(ref message,Keys.Right);
        editor.ProcessCmdKey(ref message,Keys.Up);
        Require(groupLayer.X==2 && groupLayer.Y==-1 && groupMount.X==62 && groupMount.Y==9,
            "Flechas y repetición desplazan toda la selección un píxel");
        editor.ProcessCmdKey(ref message,Keys.Control|Keys.C);
        editor.ProcessCmdKey(ref message,Keys.Control|Keys.V);
        Require(editor.selection.Count==2 && editor.layers[editor.layers.Count-1].X==26 &&
            editor.mounts[editor.mounts.Count-1].X==86 && editor.mounts[editor.mounts.Count-1].Y==33,
            "Ctrl+C y Ctrl+V conservan la disposición del grupo");
        editor.RotateSelection(90);
        foreach(Item item in editor.selection) Require(item.Angle==90,"Giro de todos los objetos seleccionados");
        editor.DeleteSelected();
        Require(editor.layers[editor.layers.Count-1]==groupLayer && editor.mounts.Count==1 &&
            editor.mounts[0]==groupMount,"Eliminar sólo el grupo seleccionado");
    }
    static void Smoke()
    {
        string folder=Path.Combine(Path.GetTempPath(),"stationBuilder-"+Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(folder);var cleanup=new List<string>();
        try
        {
            string piece=Path.Combine(folder,"piece.png");cleanup.Add(piece);
            using(var image=new Bitmap(40,20))
            using(var g=Graphics.FromImage(image))
            {g.Clear(Color.Transparent);g.FillRectangle(Brushes.White,0,0,30,20);image.Save(piece,ImageFormat.Png);}
            using(var editor=new StationBuilder())
            {
                editor.Show();Application.DoEvents();
                Require(editor.mode.SelectedIndex==0 && editor.mode.Items.Count==5,"Selector de herramientas");
                editor.AddFiles(new[] {piece},new PointF(40,10));Require(editor.layers.Count==1,"Importación PNG");
                int pointerX=editor.canvas.Width/2+40,pointerY=editor.canvas.Height/2+10;
                editor.CanvasDown(editor.canvas,new MouseEventArgs(MouseButtons.Left,1,pointerX,pointerY,0));
                editor.CanvasMove(editor.canvas,new MouseEventArgs(MouseButtons.Left,0,pointerX+24,pointerY+12,0));
                editor.dragging=false;editor.canvas.Capture=false;
                Require(Math.Abs(editor.selectedLayer.X-64)<1 && Math.Abs(editor.selectedLayer.Y-22)<1,"Arrastre en el lienzo");
                editor.selectedLayer.X=40;editor.selectedLayer.Y=10;
                editor.DuplicateSelected();Require(editor.layers.Count==2 && editor.layers[0].Asset==editor.layers[1].Asset,"Duplicación");
                editor.selectedLayer.X=40;editor.selectedLayer.Y=10;Layer top=editor.selectedLayer;
                Require(editor.HitLayer(new PointF(40,10))==top,"Selección superior");
                editor.Reorder(false);Require(editor.HitLayer(new PointF(40,10))!=top,"Orden de capas");
                editor.Reorder(true);top.Angle=90;top.Scale=2;editor.RefreshSelection();
                RectangleF bounds=LayerBounds(top);
                Require(Math.Abs(bounds.Width-40)<.01f && Math.Abs(bounds.Height-80)<.01f,"Rotación y escala");
                editor.mounts.Add(new Mount {Kind="normal",X=100,Y=100,Angle=90});
                editor.mounts.Add(new Mount {Kind="dread",X=300,Y=100,Angle=30});
                editor.mounts.Add(new Mount {Kind="pdc",X=40,Y=10,Angle=-90});

                Require(MountSize("normal").Width==164 && MountSize("dread").Height==196,"Dimensiones");
                string output=Path.Combine(folder,"station.png");
                cleanup.Add(output);cleanup.Add(Path.Combine(folder,"station.station.json"));cleanup.Add(Path.Combine(folder,"station.hardpoints.csv"));
                editor.ExportTo(output);
                Require(!File.Exists(cleanup[2]) && editor.dirty,"Exportación independiente del guardado editable");
                editor.SaveProjectTo(cleanup[2]);
                using(var png=new Bitmap(output))
                {
                    Require(png.Width==png.Height && png.GetPixel(0,0).A==0,"PNG transparente");
                    Require(png.GetPixel(png.Width/2+40,png.Height/2+10).A>0,"Composición PNG");
                }
                string csv=File.ReadAllText(cleanup[3]);
                Require(csv.Contains("atraque_dread,0,300,100,30,258,196") && csv.Contains("pdc,0"),"Ficha de hardpoints");
                editor.LoadDesign(cleanup[2]);
                Require(editor.layers.Count==2 && editor.mounts.Count==3 && editor.layers[1].Angle==90 && editor.layers[1].Scale==2,"Proyecto portátil");
                Require(editor.layers[0].Asset==editor.layers[1].Asset,"Recursos compartidos");
                StationDesign legacy=editor.CaptureDesign(editor.ExportSize());
                legacy.Version=1;
                foreach(DesignLayer item in legacy.Layers) item.ScaleX=item.ScaleY=null;
                File.WriteAllBytes(cleanup[2],Serialize(legacy));
                editor.LoadDesign(cleanup[2]);
                Require(editor.layers[1].ScaleX==2 && editor.layers[1].ScaleY==2,"Lectura de proyectos 1.0 y 1.1");
                editor.layers[1].ScaleX=3;
                editor.SaveProjectTo(cleanup[2]);editor.LoadDesign(cleanup[2]);
                Require(editor.layers[1].ScaleX==3 && editor.layers[1].ScaleY==2,"Persistencia de deformación");
                File.Delete(piece);editor.ExportTo(output);Require(File.Exists(output),"Proyecto sin PNG original");
                InteractionSmoke(editor);
                using(var preview=new Bitmap(1280,820)) editor.DrawToBitmap(preview,new Rectangle(0,0,1280,820));
            }
        }
        finally
        {
            foreach(string file in cleanup) if(File.Exists(file)) File.Delete(file);
            if(Directory.Exists(folder) && Directory.GetFileSystemEntries(folder).Length==0) Directory.Delete(folder);
        }
    }
    [STAThread]
    static void Main(string[] args)
    {
        Application.EnableVisualStyles();Application.SetCompatibleTextRenderingDefault(false);
        if(args.Length==1 && args[0]=="--smoke")
        {
            try {Smoke();} catch(Exception error) {File.WriteAllText(Path.Combine(Path.GetTempPath(),"stationBuilder-smoke-error.txt"),error.ToString());Environment.ExitCode=1;}
            return;
        }
        Application.Run(new StationBuilder());
    }
}
