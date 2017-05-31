using Gee;

namespace Engine
{
	public abstract class WorldObject
	{
		private ArrayList<WorldObjectAnimation> buffered_animations = new ArrayList<WorldObjectAnimation>();
		private ArrayList<WorldObjectAnimation> unbuffered_animations = new ArrayList<WorldObjectAnimation>();

		public signal void animation_finished(WorldObject object, WorldObjectAnimation animation);
		public signal void on_click(WorldObject object);
		public signal void on_mouse_down(WorldObject object);
		public signal void on_mouse_up(WorldObject object);
		public signal void on_mouse_over(WorldObject object);
		public signal void on_focus_lost(WorldObject object);

		protected WorldObject()
		{
			transform = new Transform();
		}

		public void process(DeltaArgs args)
		{
			foreach (var animation in unbuffered_animations)
				animation.process(args);

			if (buffered_animations.size > 0)
				buffered_animations[0].process(args);
			
			do_process(args);
		}

		public void animate(WorldObjectAnimation animation, bool buffered = true)
		{
			if (buffered)
				buffered_animations.add(animation);
			else
				unbuffered_animations.add(animation);
			
			animation.start.connect(start_animation);
			animation.animate.connect(process_animation);
			animation.finish.connect(finish_animation);
		}

		public void finish_animations()
		{
			foreach (var animation in unbuffered_animations)
				animation.do_finish();
			foreach (var animation in buffered_animations)
				animation.do_finish();
			unbuffered_animations.clear();
			buffered_animations.clear();
		}

		public void cancel_animations()
		{
			cancel_buffered_animations();
			cancel_unbuffered_animations();
		}

		public void cancel_buffered_animations()
		{
			buffered_animations.clear();
		}

		public void cancel_unbuffered_animations()
		{
			unbuffered_animations.clear();
		}

		public void remove_animation(WorldObjectAnimation animation)
		{
			buffered_animations.remove(animation);
			unbuffered_animations.remove(animation);
		}
		
		private void start_animation(WorldObjectAnimation animation)
		{
			if (animation.position_path != null)
				animation.start_position = transform.position;
			if (animation.scale_path != null)
				animation.start_scale = transform.scale;
			if (animation.rotation_path != null)
				animation.start_rotation = transform.rotation;
			
			start_custom_animation(animation);
		}

		private void process_animation(WorldObjectAnimation animation, float time)
		{
			if (animation.position_path != null)
				transform.position = animation.position_path.map(time);
			if (animation.scale_path != null)
				transform.scale = animation.scale_path.map(time);
			if (animation.rotation_path != null)
				transform.rotation = animation.rotation_path.map(time);

			process_custom_animation(animation, time);
			apply_transform(transform);
		}

		private void finish_animation(WorldObjectAnimation animation)
		{
			remove_animation(animation);
			animation_finished(this, animation);
		}

		public virtual void get_picking(PickingResult result)
		{
			if (!selectable)
				return;

			float dist = Calculations.get_collision_distance(result.ray, obb, transform.get_full_matrix());
			if (dist < 0)
				return;

			if (result.distance < 0 || dist < result.distance)
			{
				result.obj = this;
				result.distance = dist;
			}
		}

		protected virtual void start_custom_animation(WorldObjectAnimation animation) {}
		protected virtual void process_custom_animation(WorldObjectAnimation animation, float time) {}

		protected virtual void do_process(DeltaArgs args) {}
		protected virtual void apply_transform(Transform transform) {}
		public virtual void add_to_scene(RenderScene3D scene) {}

		public Transform transform { get; private set; }
		public bool selectable { get; set; }
		public Vec3 obb { get; protected set; }
	}	
}