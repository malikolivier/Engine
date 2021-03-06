public abstract class Container : Object
{
    private bool _loaded = false;
    private Vec2 _position = Vec2(0, 0);
    private Size2 _size = Size2(1, 1);
    private Vec2 _inner_anchor = Vec2(0.5f, 0.5f);
    private Vec2 _outer_anchor = Vec2(0.5f, 0.5f);
    private Size2 _relative_size = Size2(1, 1);
    private Rectangle _rect;
    private ResizeStyle _resize_style = ResizeStyle.RELATIVE;
    private bool _scissor = false;
    private Rectangle _scissor_box;
    private bool _visible = true;

    protected Gee.ArrayList<Container> children = new Gee.ArrayList<Container>();
    protected weak RenderWindow? parent_window;
    private weak Container? parent;

    public void add_child(Container child)
    {
        child.set_parent(this);
        if (!child.loaded)
            child.added();
        child._loaded = true;
        child.resize();
        children.add(child);
    }

    public void add_child_back(Container child)
    {
        child.set_parent(this);
        if (!child.loaded)
            child.added();
        child._loaded = true;
        child.resize();
        children.insert(0, child);
    }

    public void remove_child(Container child)
    {
        children.remove(child);
        child.removed();
        child.set_parent(null);
    }

    private void set_parent(Container? parent)
    {
        this.parent = parent;

        if (parent == null)
            parent_window = null;
        else
            parent_window = parent.parent_window;
    }

    public void process(DeltaArgs delta)
    {
        for (int i = children.size - 1; i >= 0 && i < children.size; i--)
            children[i].process(delta);
        do_process(delta);
    }

    public virtual void render(RenderState state, RenderScene2D scene)
    {
        if (!visible)
            return;

        do_render(state, scene);

        for (int i = 0; i < children.size; i++)
            children[i].render(state, scene);
    }

    public void mouse_event(MouseEventArgs mouse)
    {
        if (!visible)
            return;

        for (int i = children.size - 1; i >= 0 && i < children.size; i--)
            children[i].mouse_event(mouse);
        do_mouse_event(mouse);
    }

    public void mouse_move(MouseMoveArgs mouse)
    {
        if (!visible)
            return;

        for (int i = children.size - 1; i >= 0 && i < children.size; i--)
            children[i].mouse_move(mouse);
        do_mouse_move(mouse);
    }

    public void key_press(KeyArgs key)
    {
        if (!visible)
            return;

        for (int i = children.size - 1; i >= 0 && i < children.size; i--)
            children[i].key_press(key);

        do_key_press(key);
    }

    public void text_input(TextInputArgs text)
    {
        if (!visible)
            return;

        for (int i = children.size - 1; i >= 0 && i < children.size; i--)
            children[i].text_input(text);
        do_text_input(text);
    }

    public void text_edit(TextEditArgs text)
    {
        if (!visible)
            return;

        for (int i = children.size - 1; i >= 0 && i < children.size; i--)
            children[i].text_edit(text);
        do_text_edit(text);
    }

    public void resize()
    {
        Rectangle prect = parent_rect;

        if (resize_style == ResizeStyle.RELATIVE)
            _size = Size2(prect.width * relative_size.width, prect.height * relative_size.height);

        Vec2 pos = Vec2
        (
            position.x - size.width  * inner_anchor.x + prect.x + prect.width  * outer_anchor.x,
            position.y - size.height * inner_anchor.y + prect.y + prect.height * outer_anchor.y
        );

        _rect = Rectangle(pos.x, pos.y, size.width, size.height);

        foreach (Container child in children)
            child.resize();

        resized();
        size_changed();
    }

    public Vec2 to_parent_local(Vec2 global)
    {
        if (parent != null)
            global = parent.to_local(global);
        return global;
    }

    public Vec2 to_local(Vec2 global)
    {
        global = global.minus(position);
        if (parent != null)
        {
            //global = global.minus(Vec2(outer_anchor.x * parent.size.width, outer_anchor.y * parent.size.height));
            global = parent.to_local(global);
        }

        return global;
    }

    /*public Vec2 to_global(Vec2 local)
    {
        if (parent != null)
            local = parent.to_global(local.plus(parent.position));

        return local;
    }*/

    protected void start_text_input()
    {
        window.start_text_input();
    }

    protected void stop_text_input()
    {
        window.stop_text_input();
    }

    protected string get_clipboard_text()
    {
        return window.get_clipboard_text();
    }

    protected void set_clipboard_text(string text)
    {
        window.set_clipboard_text(text);
    }

    public RenderWindow window { get { return parent_window; } }
    protected virtual void added() {}
    protected virtual void removed() {}
    protected virtual void resized() {}
    protected virtual void do_render(RenderState state, RenderScene2D scene) {}
    protected virtual void do_process(DeltaArgs delta) {}
    protected virtual void do_mouse_event(MouseEventArgs mouse) {}
    protected virtual void do_mouse_move(MouseMoveArgs mouse) {}
    protected virtual void do_key_press(KeyArgs key) {}
    protected virtual void do_text_input(TextInputArgs text) {}
    protected virtual void do_text_edit(TextEditArgs text) {}

    protected ResourceStore store { get { return parent_window.store; } }

    public signal void visible_changed();
    public signal void size_changed();

    protected Rectangle parent_rect
    {
        get
        {
            if (parent != null)
                return parent.rect;
            else if (parent_window != null)
                return Rectangle(0, 0, parent_window.size.width, parent_window.size.height);
            return Rectangle(0, 0, 1, 1);
        }
    }

    public Size2i window_size
    {
        get
        {
            if (parent_window == null)
                return Size2i(1, 1);
            return parent_window.size;
        }
    }

    public Vec2 position
    {
        get { return _position; }
        set
        {
            _position = value;
            resize();
        }
    }

    public Size2 size
    {
        get { return _size; }
        set
        {
            _size = value;
            resize();
        }
    }

    public Size2 relative_size
    {
        get { return _relative_size; }
        set
        {
            _relative_size = value;
            resize();
        }
    }

    public Vec2 outer_anchor
    {
        get { return _outer_anchor; }
        set
        {
            _outer_anchor = value;
            resize();
        }
    }

    public Vec2 inner_anchor
    {
        get { return _inner_anchor; }
        set
        {
            _inner_anchor = value;
            resize();
        }
    }

    public Rectangle rect { get { return _rect; } }
    public ResizeStyle resize_style
    {
        get { return _resize_style; }
        set
        {
            _resize_style = value;
            resize();
        }
    }

    public Vec2 normal_position
    {
        get
        {
            return Vec2(parent.size.width  * outer_anchor.x - size.width  * inner_anchor.x + position.x,
                        parent.size.height * outer_anchor.y - size.height * inner_anchor.y + position.y);
        }
    }

    public bool scissor
    {
        get { return _scissor; }
        set
        {
            _scissor = value;
            foreach (var child in children)
                child.scissor = value;
        }
    }

    public Rectangle scissor_box
    {
        get { return _scissor_box; }
        set
        {
            _scissor_box = value;
            foreach (var child in children)
                child.scissor_box = value;
        }
    }

    public bool visible
    {
        get { return _visible; }
        set
        {
            _visible = value;
            visible_changed();
        }
    }

    public bool loaded { get { return _loaded; } }
}

public enum ResizeStyle
{
    ABSOLUTE,
    RELATIVE
}
