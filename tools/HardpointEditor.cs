using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Globalization;
using System.IO;
using System.Text;
using System.Windows.Forms;

sealed class HardpointEditor : Form
{
    sealed class Ship
    {
        public int Id, Rotation, Weapons, ClassId;
        public string Sprite, Name;
        public bool NoDirectTools;
        public override string ToString() { return Id + " · " + Name; }
    }

    sealed class Mount
    {
        public string Kind;
        public PointF Position;
        public float Bearing;
    }

    sealed class Canvas : Panel
    {
        public Canvas() { DoubleBuffered = true; }
    }

    static readonly string[] Kinds = { "motor", "misil", "cohete", "laser", "ametralladora", "mineria", "salvaging",
        "hangar_drones_tubo", "hangar_drones_rampa", "hangar_drones_plataforma",
        "hangar_cazas_tubo", "hangar_cazas_rampa", "hangar_cazas_plataforma" };
    static readonly string[] Labels = { "Motor", "Misil", "Cohete", "Láser", "Ametralladora", "Minería", "Salvaging",
        "Drones · Tubo lateral", "Drones · Rampa", "Drones · Plataforma",
        "Cazas · Tubo lateral", "Cazas · Rampa", "Cazas · Plataforma" };
    static readonly Color[] Colors = { Color.Orange, Color.HotPink, Color.Salmon, Color.Cyan, Color.Gold, Color.Khaki, Color.LimeGreen,
        Color.DeepSkyBlue, Color.CornflowerBlue, Color.Aquamarine,
        Color.MediumOrchid, Color.Plum, Color.LightPink };
    static readonly CultureInfo Numbers = CultureInfo.InvariantCulture;
    const string Header = "entidad,id,tipo,indice,x,y";

    readonly ComboBox shipPicker = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 245 };
    readonly CheckedListBox kindPicker = new CheckedListBox { Dock = DockStyle.Top, CheckOnClick = true, Height = 265 };
    readonly CheckBox symmetry = new CheckBox { Text = "Simetría", AutoSize = true, Padding = new Padding(0,5,0,0) };
    readonly Stack<List<Mount>> undo = new Stack<List<Mount>>();
    readonly Stack<List<Mount>> redo = new Stack<List<Mount>>();
    Button undoButton, redoButton;
    readonly Canvas canvas = new Canvas { Dock = DockStyle.Fill, BackColor = Color.FromArgb(17,23,36) };
    readonly ListBox list = new ListBox { Dock = DockStyle.Fill, SelectionMode = SelectionMode.MultiExtended };
    readonly CheckBox platformPreview = new CheckBox { Text = "Simular módulo de plataforma equipado", Dock = DockStyle.Top, Height = 28 };
    readonly Label status = new Label { Dock = DockStyle.Bottom, Height = 32, Padding = new Padding(12,6,0,0) };
    readonly List<Mount> mounts = new List<Mount>();
    readonly string project;
    Ship selected;
    Bitmap sprite;
    string spritePath;
    bool dirty, changingShip;
    static bool smokeMode;

    HardpointEditor(string projectDirectory)
    {
        project = projectDirectory;
        Text = "shipConfigurator 1.5 · Hangar Orbital";
        ClientSize = new Size(1120,740);
        MinimumSize = new Size(950,560);
        Font = new Font("Segoe UI",10);
        var toolbar = new FlowLayoutPanel { Dock = DockStyle.Top, Height = 46, Padding = new Padding(8,7,0,0), WrapContents = false };
        toolbar.Controls.Add(shipPicker);
        toolbar.Controls.Add(Button("Cargar PNG…",PickPng));
        toolbar.Controls.Add(symmetry);
        undoButton = Button("Deshacer",delegate { RestoreHistory(undo,redo); });
        redoButton = Button("Rehacer",delegate { RestoreHistory(redo,undo); });
        toolbar.Controls.Add(undoButton);
        toolbar.Controls.Add(redoButton);
        toolbar.Controls.Add(Button("Borrar selección",RemoveMount));
        toolbar.Controls.Add(Button("Guardar ficha",SaveClick));
        Controls.Add(canvas);
        var sidebar = new Panel { Dock = DockStyle.Right, Width = 340 };
        sidebar.Controls.Add(list);
        sidebar.Controls.Add(new Label { Text = "Puntos colocados", Dock = DockStyle.Top, Height = 27 });
        sidebar.Controls.Add(platformPreview);
        platformPreview.CheckedChanged += delegate { canvas.Invalidate(); };
        sidebar.Controls.Add(kindPicker);
        sidebar.Controls.Add(new Label { Text = "Tipos de hardpoint", Dock = DockStyle.Top, Height = 27 });
        Controls.Add(sidebar);
        Controls.Add(status);
        Controls.Add(toolbar);

        for (int i = 0; i < Labels.Length; i++) kindPicker.Items.Add(Labels[i],i == 0);
        kindPicker.ItemCheck += delegate(object sender, ItemCheckEventArgs e) {
            if (selected != null && e.NewValue == CheckState.Checked && !AllowsMount(Kinds[e.Index]))
            {
                e.NewValue = CheckState.Unchecked;
                status.Text = Labels[e.Index]+" no es compatible con "+selected.Name;
            }
        };
        symmetry.CheckedChanged += delegate { canvas.Invalidate(); };
        canvas.Paint += DrawCanvas;
        canvas.MouseDown += PlaceMount;
        list.SelectedIndexChanged += delegate {
            if (list.SelectedIndices.Count == 1)
                status.Text = IsRamp(mounts[list.SelectedIndex].Kind)
                    ? "Clic izquierdo mueve la rampa · clic derecho apunta el despegue · Supr borra"
                    : "Clic izquierdo mueve el punto · Supr borra · Esc deselecciona";
            else if (list.SelectedIndices.Count > 1) status.Text = "Supr borra los puntos seleccionados";
            canvas.Invalidate();
        };
        FormClosing += delegate(object sender, FormClosingEventArgs e) { e.Cancel = !ConfirmChanges(); };

        var catalog = File.ReadAllLines(Path.Combine(project,"attributes","ships-godot.txt"),Encoding.UTF8);
        for (int i = 1; i < catalog.Length; i++)
        {
            if (string.IsNullOrWhiteSpace(catalog[i])) continue;
            string[] row = catalog[i].Split(',');
            shipPicker.Items.Add(new Ship { Id = int.Parse(row[0]), Sprite = row[1],
                Rotation = int.Parse(row[2]), Name = row[12], Weapons = int.Parse(row[8]), ClassId = int.Parse(row[14]),
                NoDirectTools = Array.IndexOf(row[15].Split('|'),"no_direct_tools")>=0 });
        }
        shipPicker.SelectedIndexChanged += ChangeShip;
        if (shipPicker.Items.Count > 0) shipPicker.SelectedIndex = 0;
    }

    static Button Button(string caption, EventHandler click)
    {
        var button = new Button { Text = caption, AutoSize = true, Height = 30 };
        button.Click += click;
        return button;
    }

    string MountPath { get { return Path.Combine(project,"data","hardpoints","ship"+selected.Id+".txt"); } }

    bool ConfirmChanges()
    {
        if (!dirty) return true;
        var answer = MessageBox.Show(this,"¿Guardar los cambios de "+selected.Name+"?",
            "Hardpoints pendientes",MessageBoxButtons.YesNoCancel,MessageBoxIcon.Question);
        return answer == DialogResult.Yes ? Save() : answer == DialogResult.No;
    }

    void ChangeShip(object sender, EventArgs e)
    {
        if (changingShip) return;
        if (!ConfirmChanges())
        {
            changingShip = true;
            shipPicker.SelectedItem = selected;
            changingShip = false;
            return;
        }
        var ship = (Ship)shipPicker.SelectedItem;
        try
        {
            var nextMounts = new List<Mount>();
            string path = Path.Combine(project,"data","hardpoints","ship"+ship.Id+".txt");
            if (File.Exists(path))
            {
                var rows = File.ReadAllLines(path,Encoding.UTF8);
                var bearings = new Dictionary<string,float>();
                for (int i = 1; i < rows.Length; i++)
                {
                    string line = rows[i].Trim();
                    if (line.StartsWith("# rampa,", StringComparison.Ordinal))
                    {
                        var bearing = line.Split(',');
                        if (bearing.Length == 4)
                            bearings[bearing[1]+"/"+bearing[2]] = float.Parse(bearing[3],Numbers);
                        continue;
                    }
                    if (line.Length == 0 || line.StartsWith("#")) continue;
                    var fields = line.Split(',');
                    if (fields.Length != 6 || fields[0] != "nave" || fields[1] != ship.Id.ToString())
                        throw new InvalidDataException("Fila inválida en "+Path.GetFileName(path)+": "+line);
                    float heading;
                    bearings.TryGetValue(fields[2]+"/"+fields[3],out heading);
                    nextMounts.Add(new Mount { Kind = fields[2], Bearing = heading, Position = new PointF(
                        float.Parse(fields[4],Numbers),float.Parse(fields[5],Numbers)) });
                }
            }
            LoadSprite(Path.Combine(project,"assets","ships",ship.Sprite),ship.Rotation);
            selected = ship;
            mounts.Clear();
            mounts.AddRange(nextMounts);
            dirty = false;
            undo.Clear();
            redo.Clear();
            RefreshList();
            status.Text = "Proa arriba · marca uno o varios tipos y haz clic sobre la nave";
        }
        catch (Exception error)
        {
            if (smokeMode) throw;
            changingShip = true;
            shipPicker.SelectedItem = selected;
            changingShip = false;
            MessageBox.Show(this,error.Message,"No se pudo abrir la nave",MessageBoxButtons.OK,MessageBoxIcon.Error);
        }
    }

    void LoadSprite(string path, int rotation)
    {
        Bitmap next;
        using (var source = new Bitmap(path)) next = new Bitmap(source);
        if (rotation == 180) next.RotateFlip(RotateFlipType.Rotate180FlipNone);
        if (sprite != null) sprite.Dispose();
        sprite = next;
        spritePath = path;
        canvas.Invalidate();
    }

    void PickPng(object sender, EventArgs e)
    {
        if (selected == null) return;
        using (var dialog = new OpenFileDialog { Filter = "Imágenes PNG (*.png)|*.png", InitialDirectory = Path.GetDirectoryName(spritePath) })
        {
            if (dialog.ShowDialog(this) != DialogResult.OK) return;
            try
            {
                LoadSprite(dialog.FileName,selected.Rotation);
                status.Text = "PNG de referencia: "+Path.GetFileName(dialog.FileName)+" · se guardan los puntos del ID "+selected.Id;
            }
            catch (Exception error)
            {
                MessageBox.Show(this,error.Message,"No se pudo abrir el PNG",MessageBoxButtons.OK,MessageBoxIcon.Error);
            }
        }
    }

    RectangleF ImageArea()
    {
        float scale = Math.Min((canvas.ClientSize.Width-48f)/sprite.Width,(canvas.ClientSize.Height-48f)/sprite.Height);
        float width = sprite.Width*scale, height = sprite.Height*scale;
        return new RectangleF((canvas.ClientSize.Width-width)/2,(canvas.ClientSize.Height-height)/2,width,height);
    }

    void DrawCanvas(object sender, PaintEventArgs e)
    {
        if (sprite == null || canvas.Width <= 48 || canvas.Height <= 48) return;
        var area = ImageArea();
        e.Graphics.InterpolationMode = InterpolationMode.NearestNeighbor;
        e.Graphics.PixelOffsetMode = PixelOffsetMode.Half;
        e.Graphics.DrawImage(sprite,area);
        e.Graphics.DrawRectangle(Pens.SlateGray,area.X,area.Y,area.Width,area.Height);
        if (symmetry.Checked)
            using (var axis = new Pen(Color.SlateGray) { DashStyle = DashStyle.Dash })
                e.Graphics.DrawLine(axis,area.X+area.Width/2,area.Top,area.X+area.Width/2,area.Bottom);
        var count = new Dictionary<string,int>();
        for (int i = 0; i < mounts.Count; i++)
        {
            var mount = mounts[i];
            int index;
            count.TryGetValue(mount.Kind,out index);
            count[mount.Kind] = index+1;
            float x = area.X+(mount.Position.X+.5f)*area.Width;
            float y = area.Y+(mount.Position.Y+.5f)*area.Height;
            int kind = Array.IndexOf(Kinds,mount.Kind);
            using (var pen = new Pen(kind >= 0 ? Colors[kind] : Color.White,list.GetSelected(i) ? 3 : 2))
            using (var brush = new SolidBrush(pen.Color))
            {
                if (platformPreview.Checked && mount.Kind.EndsWith("_plataforma",StringComparison.Ordinal))
                {
                    float size = Math.Max(24,Math.Min(area.Width,area.Height)*.15f);
                    var pad = new RectangleF(x-size/2,y-size/2,size,size);
                    using (var shade = new SolidBrush(Color.FromArgb(95,pen.Color)))
                        e.Graphics.FillRectangle(shade,pad);
                    e.Graphics.DrawRectangle(pen,pad.X,pad.Y,pad.Width,pad.Height);
                    pad.Inflate(-4,-4);
                    e.Graphics.DrawRectangle(pen,pad.X,pad.Y,pad.Width,pad.Height);
                }
                if (IsRamp(mount.Kind))
                {
                    double angle = mount.Bearing*Math.PI/180;
                    float dx = 28*(float)Math.Sin(angle), dy = -28*(float)Math.Cos(angle);
                    using (var arrow = new AdjustableArrowCap(4,5))
                    using (var departure = new Pen(pen.Color,2) { CustomEndCap = arrow })
                    using (var arrival = new Pen(Color.FromArgb(145,pen.Color),2) { DashStyle = DashStyle.Dash, CustomEndCap = arrow })
                    {
                        e.Graphics.DrawLine(arrival,x,y,x-dx,y-dy);
                        e.Graphics.DrawLine(departure,x,y,x+dx,y+dy);
                    }
                }
                e.Graphics.FillEllipse(Brushes.Black,x-7,y-7,14,14);
                e.Graphics.DrawEllipse(pen,x-7,y-7,14,14);
                e.Graphics.DrawLine(pen,x-10,y,x+10,y);
                e.Graphics.DrawLine(pen,x,y-10,x,y+10);
                e.Graphics.DrawString(mount.Kind+" "+index,Font,brush,x+10,y-12);
            }
        }
    }

    int Count(string kind)
    {
        return mounts.FindAll(mount => mount.Kind == kind).Count;
    }

    void RecordEdit()
    {
        undo.Push(new List<Mount>(mounts));
        redo.Clear();
        dirty = true;
    }

    void RestoreHistory(Stack<List<Mount>> source, Stack<List<Mount>> destination)
    {
        if (source.Count == 0) return;
        destination.Push(new List<Mount>(mounts));
        mounts.Clear();
        mounts.AddRange(source.Pop());
        dirty = true;
        RefreshList();
        status.Text = "Cambio de historial aplicado";
    }

    protected override bool ProcessCmdKey(ref Message message, Keys keyData)
    {
        if (keyData == (Keys.Control | Keys.Z)) { RestoreHistory(undo,redo); return true; }
        if (keyData == (Keys.Control | Keys.Y) || keyData == (Keys.Control | Keys.Shift | Keys.Z))
        { RestoreHistory(redo,undo); return true; }
        if (keyData == Keys.Delete && list.SelectedIndices.Count > 0) { RemoveMount(this,EventArgs.Empty); return true; }
        if (keyData == Keys.Escape && list.SelectedIndex >= 0)
        {
            list.ClearSelected();
            status.Text = "Modo colocar puntos";
            return true;
        }
        return base.ProcessCmdKey(ref message,keyData);
    }

    void PlaceMount(object sender, MouseEventArgs e)
    {
        if (sprite == null) return;
        if (e.Button == MouseButtons.Right && list.SelectedIndices.Count == 1 && IsRamp(mounts[list.SelectedIndex].Kind))
        {
            int index = list.SelectedIndex;
            var mount = mounts[index];
            var rect = ImageArea();
            float dx = e.X-(rect.X+(mount.Position.X+.5f)*rect.Width);
            float dy = e.Y-(rect.Y+(mount.Position.Y+.5f)*rect.Height);
            if (dx*dx+dy*dy < 9) return;
            float bearing = (float)((Math.Atan2(dx,-dy)*180/Math.PI+360)%360);
            RecordEdit();
            mounts[index] = new Mount { Kind = mount.Kind, Position = mount.Position, Bearing = bearing };
            RefreshList();
            list.SetSelected(index,true);
            return;
        }
        if (e.Button != MouseButtons.Left || list.SelectedIndices.Count > 1) return;
        var area = ImageArea();
        if (!area.Contains(e.Location)) return;
        var position = new PointF((e.X-area.X)/area.Width-.5f,(e.Y-area.Y)/area.Height-.5f);
        if (symmetry.Checked && Math.Abs(e.X-area.X-area.Width/2) <= 3) position.X = 0;
        int selectedIndex = list.SelectedIndex;
        if (selectedIndex >= 0)
        {
            MoveMount(selectedIndex,position);
            return;
        }
        bool mirror = symmetry.Checked && position.X != 0;
        int needed = mirror ? 2 : 1;
        var additions = new List<Mount>();
        var full = new List<string>();
        foreach (int index in kindPicker.CheckedIndices)
        {
            string kind = Kinds[index];
            if (!AllowsMount(kind) || Count(kind)+needed > MountLimit(kind))
            {
                full.Add(Labels[index]);
                continue;
            }
            additions.Add(new Mount { Kind = kind, Position = position });
            if (mirror) additions.Add(new Mount { Kind = kind, Position = new PointF(-position.X,position.Y) });
        }
        if (additions.Count > 0)
        {
            RecordEdit();
            mounts.AddRange(additions);
            RefreshList();
        }
        status.Text = full.Count > 0 ? "Sin espacio para: "+string.Join(", ",full) :
            additions.Count > 0 ? "Puntos añadidos: "+additions.Count : "Marca al menos un tipo";
    }

    void MoveMount(int index, PointF position)
    {
        var mount = mounts[index];
        int counterpart = -1;
        if (symmetry.Checked && Math.Abs(mount.Position.X) > .00001f)
        {
            counterpart = mounts.FindIndex(other => other != mount && other.Kind == mount.Kind &&
                Math.Abs(other.Position.X+mount.Position.X) < .001f && Math.Abs(other.Position.Y-mount.Position.Y) < .001f);
        }
        if (counterpart >= 0 && position.X == 0)
        {
            status.Text = "La pareja simétrica necesita un punto a cada lado del eje";
            return;
        }
        RecordEdit();
        mounts[index] = new Mount { Kind = mount.Kind, Position = position, Bearing = mount.Bearing };
        if (counterpart >= 0)
            mounts[counterpart] = new Mount { Kind = mount.Kind, Position = new PointF(-position.X,position.Y), Bearing = mounts[counterpart].Bearing };
        RefreshList();
        status.Text = "Punto movido · siguiente clic para colocar nuevos puntos";
    }

    void RemoveMount(object sender, EventArgs e)
    {
        if (list.SelectedIndices.Count == 0) return;
        RecordEdit();
        for (int i = list.SelectedIndices.Count-1; i >= 0; i--)
            mounts.RemoveAt(list.SelectedIndices[i]);
        RefreshList();
    }

    static bool IsRamp(string kind) { return kind.EndsWith("_rampa",StringComparison.Ordinal); }

    bool AllowsMount(string kind)
    {
        if (kind.StartsWith("hangar_cazas_", StringComparison.Ordinal))
            return selected.ClassId == 4 || selected.ClassId == 5;
        if (kind.StartsWith("hangar_drones_", StringComparison.Ordinal))
            return true;
        return !selected.NoDirectTools || kind=="motor" || kind=="misil" || kind=="cohete";
    }

    int MountLimit(string kind)
    {
        return kind == "motor" || kind.StartsWith("hangar_", StringComparison.Ordinal)
            ? int.MaxValue : selected.Weapons;
    }

    void RefreshList()
    {
        list.Items.Clear();
        var checkedTypes = new bool[Kinds.Length];
        for (int i = 0; i < checkedTypes.Length; i++) checkedTypes[i] = kindPicker.GetItemChecked(i);
        kindPicker.BeginUpdate();
        kindPicker.Items.Clear();
        for (int i = 0; i < Kinds.Length; i++)
        {
            string kind=Kinds[i];
            bool allowed=AllowsMount(kind);
            string caption=!allowed ? "no compatible" : MountLimit(kind)==int.MaxValue ? Count(kind)+" puntos" : Count(kind)+"/"+MountLimit(kind);
            kindPicker.Items.Add(Labels[i]+"  ("+caption+")",allowed && checkedTypes[i]);
        }
        kindPicker.EndUpdate();
        undoButton.Enabled = undo.Count > 0;
        redoButton.Enabled = redo.Count > 0;
        var count = new Dictionary<string,int>();
        foreach (var mount in mounts)
        {
            int index;
            count.TryGetValue(mount.Kind,out index);
            count[mount.Kind] = index+1;
            list.Items.Add(string.Format(Numbers,"{0} {1}   ({2:0.000}, {3:0.000})",
                mount.Kind,index,mount.Position.X,mount.Position.Y) +
                (IsRamp(mount.Kind) ? string.Format(Numbers,"   {0:0.#}°",mount.Bearing) : ""));
        }
        canvas.Invalidate();
    }

    void SaveClick(object sender, EventArgs e) { Save(); }

    bool Save()
    {
        if (selected == null) return false;
        foreach (string kind in Kinds)
            if (Count(kind) > MountLimit(kind) ||
                (kind.StartsWith("hangar_", StringComparison.Ordinal) && Count(kind) > 0 && !AllowsMount(kind)))
            {
                status.Text = "Revisa los puntos de "+kind+" antes de guardar";
                return false;
            }
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(MountPath));
            var lines = new List<string> { Header };
            var count = new Dictionary<string,int>();
            foreach (var mount in mounts)
            {
                int index;
                count.TryGetValue(mount.Kind,out index);
                count[mount.Kind] = index+1;
                if (IsRamp(mount.Kind))
                    lines.Add(string.Format(Numbers,"# rampa,{0},{1},{2:0.000}",mount.Kind,index,mount.Bearing));
                lines.Add(string.Format(Numbers,"nave,{0},{1},{2},{3:0.00000},{4:0.00000}",
                    selected.Id,mount.Kind,index,mount.Position.X,mount.Position.Y));
            }
            string temporary = MountPath+"."+Guid.NewGuid().ToString("N")+".tmp";
            try
            {
                File.WriteAllLines(temporary,lines,new UTF8Encoding(false));
                if (File.Exists(MountPath)) File.Replace(temporary,MountPath,null);
                else File.Move(temporary,MountPath);
            }
            finally
            {
                if (File.Exists(temporary)) File.Delete(temporary);
            }
            dirty = false;
            status.Text = "Guardado: "+MountPath;
            return true;
        }
        catch (Exception error)
        {
            if (smokeMode) throw;
            MessageBox.Show(this,error.Message,"No se pudo guardar",MessageBoxButtons.OK,MessageBoxIcon.Error);
            return false;
        }
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing && sprite != null) sprite.Dispose();
        base.Dispose(disposing);
    }

    [STAThread]
    static void Main(string[] args)
    {
        Application.EnableVisualStyles();
        if (args.Length == 2 && args[0] == "--smoke")
        {
            smokeMode = true;
            try
            {
            using (var editor = new HardpointEditor(args[1]))
            {
                editor.CreateControl();
                editor.canvas.CreateControl();
                editor.PerformLayout();
                RectangleF area = editor.ImageArea();
                editor.kindPicker.SetItemChecked(0,false);
                editor.kindPicker.SetItemChecked(4,true);
                editor.kindPicker.SetItemChecked(5,true);
                editor.symmetry.Checked = true;
                var click = new MouseEventArgs(MouseButtons.Left,1,
                    (int)(area.X+area.Width*.25f),(int)(area.Y+area.Height*.75f),0);
                editor.PlaceMount(editor.canvas,click);
                editor.PlaceMount(editor.canvas,click);
                if (editor.mounts.Count != 4 || editor.Count("ametralladora") != 2 ||
                    editor.Count("mineria") != 2 || Math.Abs(editor.mounts[0].Position.X+editor.mounts[1].Position.X) > .00001f)
                    Environment.ExitCode = 1;
                editor.RestoreHistory(editor.undo,editor.redo);
                if (editor.mounts.Count != 0) Environment.ExitCode = 1;
                editor.RestoreHistory(editor.redo,editor.undo);
                if (editor.mounts.Count != 4) Environment.ExitCode = 1;
                editor.list.SelectedIndex = 0;
                editor.PlaceMount(editor.canvas,new MouseEventArgs(MouseButtons.Left,1,
                    (int)(area.X+area.Width*.35f),(int)(area.Y+area.Height*.60f),0));
                if (editor.mounts.Count != 4 || Math.Abs(editor.mounts[0].Position.X+.15f) > .02f ||
                    Math.Abs(editor.mounts[0].Position.X+editor.mounts[1].Position.X) > .00001f)
                    Environment.ExitCode = 1;
                editor.kindPicker.SetItemChecked(4,false);
                editor.kindPicker.SetItemChecked(5,false);
                editor.kindPicker.SetItemChecked(0,true);
                editor.PlaceMount(editor.canvas,click);
                editor.PlaceMount(editor.canvas,click);
                editor.PlaceMount(editor.canvas,click);
                if (editor.Count("motor") != 6) Environment.ExitCode = 1;
                editor.kindPicker.SetItemChecked(0,false);
                for (int i = 7; i < Kinds.Length; i++) editor.kindPicker.SetItemChecked(i,true);
                editor.PlaceMount(editor.canvas,click);
                for (int i = 7; i < Kinds.Length; i++)
                    if (editor.Count(Kinds[i]) != (i < 10 ? 2 : 0)) Environment.ExitCode = 1;
                editor.list.SetSelected(0,true);
                editor.list.SetSelected(2,true);
                var key = new Message();
                if (!editor.ProcessCmdKey(ref key,Keys.Delete) || editor.mounts.Count != 14)
                    Environment.ExitCode = 1;
                editor.RestoreHistory(editor.undo,editor.redo);
                int ramp = editor.mounts.FindIndex(mount => IsRamp(mount.Kind));
                editor.list.SetSelected(ramp,true);
                var rampPoint = editor.mounts[ramp].Position;
                editor.PlaceMount(editor.canvas,new MouseEventArgs(MouseButtons.Right,1,
                    (int)(area.X+(rampPoint.X+.5f)*area.Width)+40,
                    (int)(area.Y+(rampPoint.Y+.5f)*area.Height),0));
                if (Math.Abs(editor.mounts[ramp].Bearing-90)>3) Environment.ExitCode = 1;
                editor.platformPreview.Checked = true;
                int originalClass = editor.selected.ClassId;
                foreach (int capitalClass in new[] {4,5})
                {
                    editor.selected.ClassId = capitalClass;
                    for (int i = 7; i < Kinds.Length; i++)
                        if (!editor.AllowsMount(Kinds[i])) Environment.ExitCode = 1;
                }
                editor.selected.ClassId = originalClass;
                if (!editor.Save()) Environment.ExitCode = 1;
                using (var preview = new Bitmap(editor.canvas.Width,editor.canvas.Height))
                {
                    editor.canvas.DrawToBitmap(preview,new Rectangle(Point.Empty,editor.canvas.ClientSize));
                    preview.Save(Path.Combine(args[1],"preview.png"));
                }
            }
            using (var reloaded = new HardpointEditor(args[1]))
                if (reloaded.mounts.Count != 16 || Math.Abs(reloaded.mounts.Find(mount => IsRamp(mount.Kind)).Bearing-90)>3 || reloaded.Count("hangar_drones_plataforma") != 2 || reloaded.Count("motor") != 6 || reloaded.mounts[0].Kind != "ametralladora") Environment.ExitCode = 1;
            }
            catch (Exception error)
            {
                File.WriteAllText(Path.Combine(args[1],"error.txt"),error.ToString());
                Environment.ExitCode = 1;
            }
            return;
        }
        try
        {
            var directory = new DirectoryInfo(AppDomain.CurrentDomain.BaseDirectory);
            if (string.Equals(directory.Name, "releases", StringComparison.OrdinalIgnoreCase)
                && directory.Parent != null)
                directory = directory.Parent;
            Application.Run(new HardpointEditor(directory.FullName));
        }
        catch (Exception error) { MessageBox.Show(error.Message,"Editor de hardpoints",MessageBoxButtons.OK,MessageBoxIcon.Error); }
    }
}
