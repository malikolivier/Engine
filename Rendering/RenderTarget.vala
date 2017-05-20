using Gee;

public abstract class RenderTarget
{
    private RenderState? current_state = null;
    private RenderState? buffer_state = null;
    private bool running = false;
    private StepTimer timer;
    private Mutex state_mutex = Mutex();
    private Mutex prop_mutex = Mutex();

    private MainView debug_main_view;
    private DebugView debug_view;
    private DebugInfo? debug_info;
    private int debug_external_fps;
    private int debug_internal_fps;
    private int debug_new_external_fps;
    private int debug_new_internal_fps;

    private Mutex resource_mutex = Mutex();
    private ArrayList<IModelResourceHandle> to_load_models = new ArrayList<IModelResourceHandle>();
    private ArrayList<ITextureResourceHandle> to_load_textures = new ArrayList<ITextureResourceHandle>();

    private ArrayList<IModelResourceHandle> to_unload_models = new ArrayList<IModelResourceHandle>();
    private ArrayList<ITextureResourceHandle> to_unload_textures = new ArrayList<ITextureResourceHandle>();
    private ArrayList<ILabelResourceHandle> to_unload_labels = new ArrayList<ILabelResourceHandle>();

    private ArrayList<IModelResourceHandle> handles_models = new ArrayList<IModelResourceHandle>();
    private ArrayList<ITextureResourceHandle> handles_textures = new ArrayList<ITextureResourceHandle>();
    private ArrayList<ILabelResourceHandle> handles_labels = new ArrayList<ILabelResourceHandle>();

    private bool saved_v_sync = false;
    private string saved_shader_3D;
    private string saved_shader_2D;

    private string _shader_3D;
    private string _shader_2D;

    protected IWindowTarget window;
    protected ResourceStore store;

    public RenderTarget(IWindowTarget window, bool multithread_rendering, bool debug)
    {
        this.window = window;
        this.multithread_rendering = multithread_rendering;
        this.debug = debug;
        anisotropic_filtering = true;
        v_sync = saved_v_sync;
    }

    ~RenderTarget()
    {
        stop();
    }

    public void set_state(RenderState state, RenderWindow window)
    {
        debug_new_internal_fps++;

        if (debug)
            add_debug_info(state, window);
        
        if (multithread_rendering)
        {
            state_mutex.lock();
            buffer_state = state;
            state_mutex.unlock();
        }
        else
            render_cycle(state);
    }

    public bool init()
    {
        return internal_init();
    }

    public void cycle()
    {
        running = true;
        while (running)
        {
            state_mutex.lock();
            window.pump_events();
            
            if (current_state == buffer_state && current_state == null)
            {
                state_mutex.unlock();
                Thread.usleep(1000);
                continue;
            }

            current_state = buffer_state;
            state_mutex.unlock();

            render_cycle(current_state);

            // TODO: Fix fullscreen v-sync issues
        }
    }

    private bool internal_init()
    {
        timer = new StepTimer();
        return renderer_init();
    }

    public void stop()
    {
        running = false;
    }

    public IModelResourceHandle load_model(InputResourceModel model)
    {
        resource_mutex.lock();
        IModelResourceHandle ret = init_model(model);
        to_load_models.add(ret);
        resource_mutex.unlock();

        return ret;
    }

    public ITextureResourceHandle load_texture(InputResourceTexture texture)
    {
        resource_mutex.lock();
        ITextureResourceHandle ret = init_texture(texture);
        to_load_textures.add(ret);
        resource_mutex.unlock();

        return ret;
    }

    public ILabelResourceHandle load_label()
    {
        resource_mutex.lock();
        ILabelResourceHandle ret = init_label();
        handles_labels.add(ret);
        resource_mutex.unlock();

        return ret;
    }

    public void unload_model(IModelResourceHandle model)
    {
        resource_mutex.lock();
        to_unload_models.add(model);
        resource_mutex.unlock();
    }

    public void unload_texture(ITextureResourceHandle texture)
    {
        resource_mutex.lock();
        to_unload_textures.add(texture);
        resource_mutex.unlock();
    }

    public void unload_label(ILabelResourceHandle label)
    {
        resource_mutex.lock();
        to_unload_labels.add(label);
        resource_mutex.unlock();
    }

    private void render_cycle(RenderState state)
    {
        debug_new_external_fps++;

        if (timer.elapsed())
            do_secondly();

        unload_resources();
        load_resources();
        check_settings();
        if (debug)
            update_debug(state);
        prepare_state_internal(state);
        render(state);
        window.swap();
    }

    private void unload_resources()
    {
        resource_mutex.lock();
        while (to_unload_models.size != 0)
        {
            IModelResourceHandle model = to_unload_models.remove_at(0);
            handles_models.remove(model);
            resource_mutex.unlock();
            do_unload_model(model);
            resource_mutex.lock();
        }

        while (to_unload_textures.size != 0)
        {
            ITextureResourceHandle texture = to_unload_textures.remove_at(0);
            handles_textures.remove(texture);
            resource_mutex.unlock();
            do_unload_texture(texture);
            resource_mutex.lock();
        }

        while (to_unload_labels.size != 0)
        {
            ILabelResourceHandle label = to_unload_labels.remove_at(0);
            handles_labels.remove(label);
            resource_mutex.unlock();
            do_unload_label(label);
            resource_mutex.lock();
        }
        resource_mutex.unlock();
    }

    private void load_resources()
    {
        resource_mutex.lock();
        while (to_load_models.size != 0)
        {
            IModelResourceHandle model = to_load_models.remove_at(0);
            handles_models.add(model);
            resource_mutex.unlock();
            do_load_model(model);
            resource_mutex.lock();
        }

        while (to_load_textures.size != 0)
        {
            ITextureResourceHandle texture = to_load_textures.remove_at(0);
            handles_textures.add(texture);
            resource_mutex.unlock();
            do_load_texture(texture);
            resource_mutex.lock();
        }
        resource_mutex.unlock();
    }

    private void check_settings()
    {
        bool new_v_sync = v_sync;

        if (new_v_sync != saved_v_sync)
        {
            saved_v_sync = new_v_sync;
            change_v_sync(saved_v_sync);
        }

        string new_shader_3D = shader_3D;

        if (new_shader_3D != saved_shader_3D)
        {
            saved_shader_3D = new_shader_3D;
            change_shader_3D(saved_shader_3D);
        }

        string new_shader_2D = shader_2D;

        if (new_shader_2D != saved_shader_2D)
        {
            saved_shader_2D = new_shader_2D;
            change_shader_2D(saved_shader_2D);
        }
    }

    private void prepare_state_internal(RenderState state)
    {
        foreach (RenderScene scene in state.scenes)
        {
            if (scene is RenderScene2D)
            {
                RenderScene2D s = scene as RenderScene2D;
                foreach (RenderObject2D obj in s.objects)
                {
                    if (obj is RenderLabel2D)
                    {
                        RenderLabel2D label = obj as RenderLabel2D;
                        LabelResourceHandle handle = (LabelResourceHandle)label.reference.handle;

                        bool invalid = false;
                        if (!handle.created ||
                            label.font_type != handle.font_type ||
                            label.font_size != handle.font_size ||
                            label.text != handle.text)
                            invalid = true;

                        if (!invalid)
                            continue;

                        LabelBitmap bitmap = store.generate_label_bitmap(label);
                        do_load_label(handle, bitmap);

                        handle.created = true;
                        handle.font_type = label.font_type;
                        handle.font_size = label.font_size;
                        handle.text = label.text;
                    }
                }
            }
            else if (scene is RenderScene3D)
                update_labels_3D((scene as RenderScene3D).queue);
        }
    }

    private void update_labels_3D(RenderQueue3D queue)
    {
        foreach (RenderQueue3D sub in queue.sub_queues)
            update_labels_3D(sub);

        foreach (RenderObject3D obj in queue.objects)
        {
            if (obj is RenderLabel3D)
            {
                RenderLabel3D label = obj as RenderLabel3D;
                LabelResourceHandle handle = (LabelResourceHandle)label.reference.handle;

                bool invalid = false;
                if (!handle.created ||
                    label.font_type != handle.font_type ||
                    label.font_size != handle.font_size ||
                    label.text != handle.text)
                    invalid = true;

                if (!invalid)
                    continue;

                LabelBitmap bitmap = store.generate_label_bitmap_3D(label);
                do_load_label(handle, bitmap);

                handle.created = true;
                handle.font_type = label.font_type;
                handle.font_size = label.font_size;
                handle.text = label.text;
            }
        }
    }

    private void add_debug_info(RenderState state, RenderWindow window)
    {
        if (debug_main_view == null)
        {
            debug_main_view = new MainView(window);
            debug_view = new DebugView();

            debug_main_view.add_child(debug_view);
        }

        debug_main_view.set_window(window);
        debug_main_view.resize();
        state_mutex.lock();
        DebugInfo info = debug_info;
        state_mutex.unlock();
        debug_view.info = info;
        debug_main_view.start_process(state.delta);
        debug_main_view.start_render(state);
    }

    private void update_debug(RenderState state)
    {
        string[] strings =
        {
            "FPS: " + debug_external_fps.to_string(),
            "CPS: " + debug_internal_fps.to_string(),
            "Model handles: " + handles_models.size.to_string(),
            "Texture handles: " + handles_textures.size.to_string(),
            "Label handles: " + handles_labels.size.to_string()
        };

        DebugInfo info = new DebugInfo();
        info.add_strings(strings);

        foreach (RenderScene scene in state.scenes)
        {
            if (scene is RenderScene3D)
            {
                RenderQueue3D queue = (scene as RenderScene3D).queue;

                info.add_string("Model queues: " + queue.sub_queues.size.to_string());
                
                int i = 0;
                foreach (RenderQueue3D sub in queue.sub_queues)
                {
                    info.add_string("Texture queues[" + (++i).to_string() + "]: " + sub.sub_queues[0].objects.size.to_string());
                }
            }
        }
        
        info.add_strings(get_debug_strings());

        state_mutex.lock();
        debug_info = info;
        state_mutex.unlock();
    }

    public Mat4 get_projection_matrix(float view_angle, float aspect_ratio)
    {
        view_angle   *= 0.6f;
        float z_near  = 0.5f * aspect_ratio;
        float z_far   =   30 * aspect_ratio;
        float z_plus  = z_far + z_near;
        float z_minus = z_far - z_near;
        float z_mul   = z_far * z_near;

        float vtan1 = 1 / (float)Math.tan(view_angle);
        float vtan2 = vtan1 * aspect_ratio;

        Vec4 v1 = {vtan1,    0,               0,                 0                  };
        Vec4 v2 = {0,        vtan2,           0,                 0                  };
        Vec4 v3 = {0,        0,              -z_plus / z_minus, -2 * z_mul / z_minus};
        Vec4 v4 = {0,        0,              -1,                 0                  };

        return new Mat4.with_vecs(v1, v2, v3, v4);
    }

    public abstract void render(RenderState state);
    protected abstract bool renderer_init();

    protected abstract void do_load_model(IModelResourceHandle handle);
    protected abstract void do_load_texture(ITextureResourceHandle handle);
    protected abstract void do_load_label(ILabelResourceHandle handle, LabelBitmap bitmap);

    protected abstract void do_unload_model(IModelResourceHandle handle);
    protected abstract void do_unload_texture(ITextureResourceHandle handle);
    protected abstract void do_unload_label(ILabelResourceHandle handle);

    protected abstract IModelResourceHandle init_model(InputResourceModel model);
    protected abstract ITextureResourceHandle init_texture(InputResourceTexture texture);
    protected abstract LabelResourceHandle init_label();

    protected abstract void change_v_sync(bool v_sync);
    protected abstract bool change_shader_3D(string name);
    protected abstract bool change_shader_2D(string name);
    protected virtual string[] get_debug_strings() { return new string[0]; }
    protected virtual void do_secondly()
    {
        debug_external_fps = debug_new_external_fps;
        debug_internal_fps = debug_new_internal_fps;
        debug_new_external_fps = 0;
        debug_new_internal_fps = 0;
    }

    public ResourceStore resource_store { get { return store; } }
    public bool v_sync { get; set; }
    public bool anisotropic_filtering { get; set; }
    public bool multithread_rendering { get; private set; }
    public bool debug { get; private set; }

    public string shader_3D
    {
        owned get
        {
            prop_mutex.lock();
            string s = _shader_3D;
            prop_mutex.unlock();
            return s;
        }

        set
        {
            prop_mutex.lock();
            _shader_3D = value;
            prop_mutex.unlock();
        }
    }

    public string shader_2D
    {
        owned get
        {
            prop_mutex.lock();
            string s = _shader_2D;
            prop_mutex.unlock();
            return s;
        }

        set
        {
            prop_mutex.lock();
            _shader_2D = value;
            prop_mutex.unlock();
        }
    }

    protected abstract class LabelResourceHandle : ILabelResourceHandle, Object
    {
        public bool created { get; set; }
        public string font_type { get; set; }
        public float font_size { get; set; }
        public string text { get; set; }
    }
}
