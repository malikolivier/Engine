public abstract class RenderObject3D : Transformable3D
{
    public RenderObject3D(RenderModel model, RenderMaterial material)
    {
        this.model = model;
        this.material = material;
    }

    protected override Transformable3D copy_transformable(Transform transform)
    {
        RenderObject3D obj = copy_object();
        
        obj.transform = transform;
        obj.model = model;
        obj.material = material.copy();

        return obj;
    }

    public RenderModel model { get; set; }
    public RenderMaterial material { get; set; }
    protected abstract RenderObject3D copy_object();
}

public class RenderBody3D : RenderObject3D
{
    public RenderBody3D(RenderModel model, RenderMaterial material)
    {
        base(model, material);
    }

    protected override RenderObject3D copy_object()
    {
        RenderBody3D obj = new RenderBody3D(model, material.copy());
        obj.texture = texture;

        return obj;
    }

    public RenderTexture? texture { get; set; }
}

public class RenderLabel3D : RenderObject3D
{
    private string _font_type;
    private float _font_size;
    private string _text;
    private bool _bold;
    private float _size = FONT_SIZE_MULTIPLIER;

    public RenderLabel3D(LabelResourceReference reference, RenderModel model)
    {
        base(model, new RenderMaterial());

        this.reference = reference;

        _font_type = "Noto Sans CJK JP";
        _font_size = 40;
        _text = "";
        _bold = false;

        color = Color.white();
        material.ambient_material_strength = 0;
        material.specular_material_strength = 0;
        material.ambient_color = Color.none();
        material.diffuse_color = Color.none();
        material.specular_color = Color.none();
    }

    protected override RenderObject3D copy_object()
    {
        RenderLabel3D img = new RenderLabel3D(reference, model);
        img.material = material.copy();
        img.info = info;
        img._font_type = _font_type;
        img._font_size = _font_size;
        img._text = _text;
        img._bold = _bold;

        return img;
    }

    private void update()
    {
        info = reference.update(get_full_font_type(), font_size, text);
    }

    private string get_full_font_type()
    {
        string font = font_type;
        if (bold)
            font += " Bold";
        return font;
    }

    public LabelInfo? info { get; private set; }
    public LabelResourceReference reference { get; private set; }

    public string font_type
    {
        get { return _font_type; }
        set
        {
            if (_font_type == value)
                return;

            _font_type = value;
            update();
        }
    }

    public float font_size
    {
        get { return _font_size; }
        set
        {
            if (_font_size == value)
                return;

            _font_size = value;
            update();
        }
    }

    public string text
    {
        get { return _text; }
        set
        {
            if (_text == value)
                return;

            _text = value;
            update();
        }
    }

    public bool bold
    {
        get { return _bold; }
        set
        {
            if (_bold == value)
                return;

            _bold = value;
            update();
        }
    }

    public Color color
    {
        get { return Color(material.diffuse_color.r + 1, material.diffuse_color.g + 1, material.diffuse_color.b + 1, material.diffuse_color.a + 1); }
        set
        {
            material.diffuse_color = Color(value.r - 1, value.g - 1, value.b - 1, value.a - 1);
            material.ambient_color = material.diffuse_color;
        }
    }

    public Transform get_label_transform()
    {
        Transform t = transform.copy_full_parentless();

        Vec3 s = font_sizing();
        t.scale = Vec3(t.scale.x * s.x, t.scale.y * s.y, t.scale.z * s.z);

        return t;
    }

    private Vec3 font_sizing()
    {
        return Vec3(info.size.width / font_size * FONT_SIZE_MULTIPLIER * _size, 1, info.size.height / font_size * FONT_SIZE_MULTIPLIER * _size);
    }

    public Vec3 end_size
    {
        get
        {
            Vec3 font_scale = font_sizing();
            Vec3 trans_scale = transform.scale;
            return Vec3(model.size.x * font_scale.x * trans_scale.x, 0, model.size.z * font_scale.z * trans_scale.z);
        }
    }

    private const float FONT_SIZE_MULTIPLIER = 0.2f;
}
