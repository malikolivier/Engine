public class WorldLabel : WorldObjectTransformable
{
	private RenderLabel3D label;

	public WorldLabel(ResourceStore store)
	{
        RenderLabel3D label = store.create_label_3D();
        base(label);
        this.label = label;
	}

    public string font_type { get { return label.font_type; } set { label.font_type = value; } }
    public float font_size { get { return label.font_size; } set { label.font_size = value; } }
    public string text { get { return label.text; } set { label.text = value; } }
    public bool bold { get { return label.bold; } set { label.bold = value; } }
    public Color color { get { return label.color; } set { label.color = value; } }
    public Vec3 end_size { get { return label.end_size; } }
}