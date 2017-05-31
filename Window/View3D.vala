namespace Engine
{
    public abstract class View3D : Container
    {
        public View3D()
        {
            world = new World(this);
            world_scale_width = 1;
        }

        protected override void do_render(RenderState state, RenderScene2D scene_2d)
        {
            RenderScene3D scene = new RenderScene3D(state.copy_state, state.screen_size, world_scale_width, rect);
            world.add_to_scene(scene);
            state.add_scene(scene);
        }

        protected override void do_process(DeltaArgs args)
        {
            world.process(args);
            process_3d(args);
        }
        
        protected virtual void process_3d(DeltaArgs args) {}

        protected override void do_mouse_event(MouseEventArgs mouse)
        {
            world.mouse_event(mouse);
        }

        protected override void do_mouse_move(MouseMoveArgs mouse)
        {
            world.mouse_move(mouse);
        }

        protected float world_scale_width { get; protected set; }
        protected World world { get; private set; }
    }
}