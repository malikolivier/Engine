using GL;
using Gee;

public class OpenGLRenderer : RenderTarget
{
    private const int MAX_LIGHTS = 2;

    private const int POSITION_ATTRIBUTE = 0;
    private const int TEXTURE_ATTRIBUTE = 1;
    private const int NORMAL_ATTRIBUTE = 2;

    private float anisotropic = 0;

    private OpenGLShaderProgram3D program_3D;
    private OpenGLShaderProgram2D program_2D;

    private Size2i view_size;

    private int debug_2D_draws;
    private int debug_3D_draws;
    private int debug_scene_switches;

    public OpenGLRenderer(IWindowTarget window, bool multithread_rendering, bool debug)
    {
        base(window, multithread_rendering, debug);
        store = new ResourceStore(this);
    }

    protected override bool renderer_init()
    {
        if (glEnable == null)
        {
            EngineLog.log(EngineLogType.RENDERING, "OpenGLRenderer", "Invalid GL context");
            return false;
        }

        if (glCreateShader == null)
        {
            EngineLog.log(EngineLogType.RENDERING, "OpenGLRenderer", "Invalid GL 2.1 context");
            return false;
        }

        glEnable(GL_CULL_FACE);
        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_LEQUAL);

        glEnable(GL_LINE_SMOOTH);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_FRAMEBUFFER_SRGB);
        glEnable(GL_MULTISAMPLE);

        change_v_sync(v_sync);

        program_3D = new OpenGLShaderProgram3D(MAX_LIGHTS, POSITION_ATTRIBUTE, TEXTURE_ATTRIBUTE, NORMAL_ATTRIBUTE);
        if (!program_3D.init())
            return false;

        program_2D = new OpenGLShaderProgram2D();
        if (!program_2D.init())
            return false;

        float aniso[1];
        glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, aniso);
        anisotropic = aniso[0];

        return true;
    }

    public override void render(RenderState state)
    {
        debug_2D_draws = 0;
        debug_3D_draws = 0;
        debug_scene_switches = 0;

        setup_projection(state.screen_size);
        glClearColor(state.back_color.r, state.back_color.g, state.back_color.b, state.back_color.a);
        glClear(GL_COLOR_BUFFER_BIT);

        foreach (RenderScene scene in state.scenes)
        {
            glClear(GL_DEPTH_BUFFER_BIT);

            if (scene is RenderScene2D)
                render_scene_2D(scene as RenderScene2D);
            else if (scene is RenderScene3D)
                render_scene_3D(scene as RenderScene3D);
            
            debug_scene_switches++;
        }

        if (debug)
            get_debug_messages();
    }

    private void render_scene_3D(RenderScene3D scene)
    {
        OpenGLShaderProgram3D program = program_3D;

        Mat4 projection_matrix = get_projection_matrix(scene.focal_length, (float)scene.screen_size.width / scene.screen_size.height);
        Mat4 view_matrix = scene.view_matrix;
        Mat4 scene_matrix = scene.scene_matrix;

        program.apply_scene(projection_matrix.mul_mat(scene_matrix), view_matrix, scene.lights);

        int last_texture_handle = -1;
        int last_array_handle = -1;

        foreach (Transformable3D obj in scene.objects)
            render_transformable(obj, program, ref last_texture_handle, ref last_array_handle);
    }

    private void render_transformable(Transformable3D transformable, OpenGLShaderProgram3D program, ref int last_texture_handle, ref int last_array_handle)
    {
        if (transformable is RenderGeometry3D)
            render_geometry_3D(transformable as RenderGeometry3D, program, ref last_texture_handle, ref last_array_handle);
        else if (transformable is RenderBody3D)
            render_body_3D(transformable as RenderBody3D, program, ref last_texture_handle, ref last_array_handle);
        else if (transformable is RenderLabel3D)
            render_label_3D(transformable as RenderLabel3D, program, ref last_texture_handle, ref last_array_handle);
    }

    private void render_geometry_3D(RenderGeometry3D geometry, OpenGLShaderProgram3D program, ref int last_texture_handle, ref int last_array_handle)
    {
        foreach (Transformable3D obj in geometry.geometry)
            render_transformable(obj, program, ref last_texture_handle, ref last_array_handle);
    }

    private void render_body_3D(RenderBody3D obj, OpenGLShaderProgram3D program, ref int last_texture_handle, ref int last_array_handle)
    {
        if (obj.material.alpha <= 0)
            return;

        bool use_texture = false;

        if (obj.texture != null)
        {
            OpenGLTextureResourceHandle texture_handle = obj.texture.handle as OpenGLTextureResourceHandle;
            use_texture = true;

            if (last_texture_handle != texture_handle.handle)
            {
                last_texture_handle = (int)texture_handle.handle;
                glBindTexture(GL_TEXTURE_2D, texture_handle.handle);
            }
        }

        OpenGLModelResourceHandle model_handle = obj.model.handle as OpenGLModelResourceHandle;

        if (last_array_handle != model_handle.array_handle)
        {
            last_array_handle = (int)model_handle.array_handle;
            OpenGLFunctions.glBindVertexArray(model_handle.array_handle);
        }

        Mat4 model_matrix = obj.transform.get_full_matrix();
        program.render_object(model_handle.triangle_count, model_matrix, obj.material, use_texture);
        debug_3D_draws++;
    }

    private void render_label_3D(RenderLabel3D label, OpenGLShaderProgram3D program, ref int last_texture_handle, ref int last_array_handle)
    {
        OpenGLLabelResourceHandle label_handle = label.reference.handle as OpenGLLabelResourceHandle;
        OpenGLModelResourceHandle model_handle = label.model.handle as OpenGLModelResourceHandle;

        if (last_texture_handle != label_handle.handle)
        {
            last_texture_handle = (int)label_handle.handle;
            glBindTexture(GL_TEXTURE_2D, label_handle.handle);
        }

        if (last_array_handle != model_handle.array_handle)
        {
            last_array_handle = (int)model_handle.array_handle;
            OpenGLFunctions.glBindVertexArray(model_handle.array_handle);
        }

        Mat4 model_matrix = label.get_label_transform().get_full_matrix();
        program.render_object(model_handle.triangle_count, model_matrix, label.material, true);
        debug_3D_draws++;
    }

    private void render_scene_2D(RenderScene2D scene)
    {
        OpenGLShaderProgram2D program = program_2D;

        program.apply_scene();
        bool scissors = false;
        float aspect = (float)scene.screen_size.width / scene.screen_size.height;

        foreach (RenderObject2D obj in scene.objects)
        {
            if (obj.scissor != scissors)
            {
                if (obj.scissor)
                {
                    glEnable(GL_SCISSOR_TEST);
                    glScissor((int)Math.round(obj.scissor_box.x),
                              (int)Math.round(obj.scissor_box.y),
                              (int)Math.round(obj.scissor_box.width),
                              (int)Math.round(obj.scissor_box.height));
                }
                else
                    glDisable(GL_SCISSOR_TEST);

                scissors = obj.scissor;
            }

            if (obj is RenderImage2D)
                render_image_2D(obj as RenderImage2D, program, aspect);
            else if (obj is RenderLabel2D)
                render_label_2D(obj as RenderLabel2D, program, scene.screen_size, aspect);
            else if (obj is RenderRectangle2D)
                render_rectangle_2D(obj as RenderRectangle2D, program, aspect);
            debug_2D_draws++;
        }

        if (scissors)
            glDisable(GL_SCISSOR_TEST);
    }

    private void render_image_2D(RenderImage2D obj, OpenGLShaderProgram2D program, float aspect)
    {
        OpenGLTextureResourceHandle texture_handle = obj.texture.handle as OpenGLTextureResourceHandle;
        glBindTexture(GL_TEXTURE_2D, (GLuint)texture_handle.handle);

        Mat3 model_transform = Calculations.get_model_matrix_3(obj.position, obj.rotation, obj.scale, aspect);

        program.render_object(model_transform, obj.diffuse_color, true);
    }

    private void render_label_2D(RenderLabel2D label, OpenGLShaderProgram2D program, Size2i screen_size, float aspect)
    {
        OpenGLLabelResourceHandle label_handle = label.reference.handle as OpenGLLabelResourceHandle;
        glBindTexture(GL_TEXTURE_2D, label_handle.handle);

        Vec2 p = label.position;

        // Round position to nearest pixel
        p = Vec2(Math.rintf(p.x * (float)screen_size.width  / 2) / (float)screen_size.width  * 2,
                 Math.rintf(p.y * (float)screen_size.height / 2) / (float)screen_size.height * 2);

        // If the label and screen size don't have the same mod 2, we are misaligned by exactly half a pixel
        if (label.info.size.width  % 2 != screen_size.width  % 2)
            p.x += 1.0f / screen_size.width;
        if (label.info.size.height % 2 != screen_size.height % 2)
            p.y += 1.0f / screen_size.height;

        Mat3 model_transform = Calculations.get_model_matrix_3(p, label.rotation, label.scale, aspect);

        program.render_object(model_transform, label.diffuse_color, true);
    }

    private void render_rectangle_2D(RenderRectangle2D rectangle, OpenGLShaderProgram2D program, float aspect)
    {
        Mat3 model_transform = Calculations.get_model_matrix_3(rectangle.position, rectangle.rotation, rectangle.scale, aspect);
        program.render_object(model_transform, rectangle.diffuse_color, false);
    }

    ///////////////////////////

    protected override IModelResourceHandle init_model(InputResourceModel model)
    {
        return new OpenGLModelResourceHandle(model);
    }

    protected override ITextureResourceHandle init_texture(InputResourceTexture texture)
    {
        return new OpenGLTextureResourceHandle(texture);
    }

    protected override RenderTarget.LabelResourceHandle init_label()
    {
        return new OpenGLLabelResourceHandle();
    }

    protected override void do_load_model(IModelResourceHandle model)
    {
        OpenGLModelResourceHandle handle = model as OpenGLModelResourceHandle;
        InputResourceModel resource = handle.model;

        int len = 10 * (int)sizeof(float);
        uint triangles[1];

        glGenBuffers(1, triangles);
        glBindBuffer(GL_ARRAY_BUFFER, triangles[0]);
        glBufferData(GL_ARRAY_BUFFER, len * resource.points.length, (GLvoid[])resource.points, GL_STATIC_DRAW);

        uint vao[1];
        OpenGLFunctions.glGenVertexArrays(1, vao);
        OpenGLFunctions.glBindVertexArray(vao[0]);

        glEnableVertexAttribArray(POSITION_ATTRIBUTE);
        glVertexAttribPointer(POSITION_ATTRIBUTE, 4, GL_FLOAT, false, len, 0);
        glEnableVertexAttribArray(TEXTURE_ATTRIBUTE);
        glVertexAttribPointer(TEXTURE_ATTRIBUTE, 3, GL_FLOAT, false, len, 4 * (int)sizeof(float));
        glEnableVertexAttribArray(NORMAL_ATTRIBUTE);
        glVertexAttribPointer(NORMAL_ATTRIBUTE, 3, GL_FLOAT, false, len, 7 * (int)sizeof(float));

        handle.handle = triangles[0];
        handle.triangle_count = resource.points.length;
        handle.array_handle = vao[0];
        handle.model = null;
    }

    protected override void do_load_texture(ITextureResourceHandle texture)
    {
        OpenGLTextureResourceHandle handle = texture as OpenGLTextureResourceHandle;
        InputResourceTexture resource = handle.texture;

        int width = resource.size.width;
        int height = resource.size.height;

        uint tex[1];
        glGenTextures(1, tex);

        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, tex[0]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_SRGB_ALPHA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid[])resource.data);

        /*if (!resource.tile)
        {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        }*/

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        if (anisotropic_filtering && anisotropic > 0)
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, anisotropic);

        handle.handle = tex[0];
        handle.texture = null;
    }

    protected override void do_load_label(ILabelResourceHandle label_handle, LabelBitmap label)
    {
        OpenGLLabelResourceHandle handle = label_handle as OpenGLLabelResourceHandle;

        uint tex[1] = { handle.handle };
        if (handle.created)
            glDeleteTextures(1, tex);

        int width = label.size.width;
        int height = label.size.height;

        glGenTextures(1, tex);

        float aniso[1];
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, tex[0]);
        glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, aniso);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, aniso[0]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, (GLvoid[])label.data);

        handle.handle = tex[0];
    }

    protected override void do_unload_model(IModelResourceHandle model)
    {
        OpenGLModelResourceHandle handle = model as OpenGLModelResourceHandle;

        uint[] triangles = { handle.handle };
        uint[] vao = { handle.array_handle };

        glDeleteBuffers(1, triangles);
        OpenGLFunctions.glDeleteVertexArrays(1, vao);
    }

    protected override void do_unload_texture(ITextureResourceHandle label_handle)
    {
        OpenGLTextureResourceHandle handle = label_handle as OpenGLTextureResourceHandle;

        uint[] tex = { handle.handle };
        glDeleteTextures(1, tex);
    }

    protected override void do_unload_label(ILabelResourceHandle label_handle)
    {
        OpenGLLabelResourceHandle handle = label_handle as OpenGLLabelResourceHandle;

        if (handle.created)
        {
            uint[] tex = { handle.handle };
            glDeleteTextures(1, tex);
        }
    }

    protected override void change_v_sync(bool v_sync)
    {
        SDL.GL.set_swapinterval(v_sync ? 1 : 0);
    }

    protected override bool change_shader_3D(string name)
    {
        OpenGLShaderProgram3D program = new OpenGLShaderProgram3D(MAX_LIGHTS, POSITION_ATTRIBUTE, TEXTURE_ATTRIBUTE, NORMAL_ATTRIBUTE);
        if (!program.init())
            return false;

        program_3D = program;
        return true;
    }

    protected override bool change_shader_2D(string name)
    {
        OpenGLShaderProgram2D program = new OpenGLShaderProgram2D();
        if (!program.init())
            return false;

        program_2D = program;
        return true;
    }

    private void setup_projection(Size2i size)
    {
        if (view_size.width == size.width && view_size.height == size.height)
            return;
        view_size = size;

        glViewport(0, 0, view_size.width, view_size.height);
    }

    private void get_debug_messages()
    {
        uint8 buffer[8192];

        uint sources[1];
        uint types[1];
        uint ids[1];
        uint severities[1];
        int lengths[1];

        while (true)
        {
            uint ret = glGetDebugMessageLog
            (
                1,
                buffer.length,
                sources,
                types,
                ids,
                severities,
                lengths,
                buffer
            );

            if (ret == 0)
                break;

            string msg = (string)buffer;
            DebugMessage message = new DebugMessage(sources[0], types[0], ids[0], severities[0], msg);

            log_debug_message(message);
        }
    }

    private void log_debug_message(DebugMessage message)
    {
        EngineLog.log(EngineLogType.DEBUG, "OpenGLRenderer", message.message);
    }

    protected override string[] get_debug_strings()
    {
        return
        {
            "3D draws: " + debug_3D_draws.to_string(),
            "2D draws: " + debug_2D_draws.to_string(),
            "Scene switches: " + debug_scene_switches.to_string()
        };
    }

    // Private classes

    class DebugMessage
    {
        public DebugMessage(uint source, uint message_type, uint id, uint severity, string message)
        {
            this.source = source;
            this.message_type = message_type;
            this.id = id;
            this.severity = severity;
            this.message = message;
        }

        public uint source { get; private set; }
        public uint message_type { get; private set; }
        public uint id { get; private set; }
        public uint severity { get; private set; }
        public string message { get; private set; }
    }

    class OpenGLModelResourceHandle : IModelResourceHandle, Object
    {
        public OpenGLModelResourceHandle(InputResourceModel model)
        {
            this.model = model;
        }

        public InputResourceModel? model { get; set; }
        public uint handle { get; set; }
        public int triangle_count { get; set; }
        public uint array_handle { get; set; }
    }

    class OpenGLTextureResourceHandle : ITextureResourceHandle, Object
    {
        public OpenGLTextureResourceHandle(InputResourceTexture texture)
        {
            this.texture = texture;
        }

        public InputResourceTexture? texture { get; set; }
        public uint handle { get; set; }
    }

    class OpenGLLabelResourceHandle : RenderTarget.LabelResourceHandle
    {
        public OpenGLLabelResourceHandle()
        {
            created = false;
        }

        public uint handle { get; set; }
    }
}
