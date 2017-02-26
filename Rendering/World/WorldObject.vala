using Gee;

public abstract class WorldObject
{
	private ArrayList<WorldObjectAnimation> buffered_animations = new ArrayList<WorldObjectAnimation>();
	private ArrayList<WorldObjectAnimation> unbuffered_animations = new ArrayList<WorldObjectAnimation>();

	protected WorldObject()
	{
		transform = new Transform();
	}

	public void process(DeltaArgs args)
	{
		foreach (var animation in unbuffered_animations)
		{
			animation.process(args);
			if (animation.finished)
				unbuffered_animations.remove(animation);
		}

		if (buffered_animations.size > 0)
		{
			var animation = buffered_animations[0];
			animation.process(args);
			if (animation.finished)
				buffered_animations.remove_at(0);
		}
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
			animation.finish();
		foreach (var animation in buffered_animations)
			animation.finish();
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
		if (animation.relative_position)
			animation.start_position = current_position;
		if (animation.relative_scale)
			animation.start_scale = current_scale;
		if (animation.relative_rotation)
			animation.start_rotation = current_rotation;
		
		start_custom_animation(animation);
	}

	private void process_animation(WorldObjectAnimation animation, float time)
	{
		if (animation.use_position)
			transform.position = position_path.map(time);
		if (animation.use_scale)
			transform.scale = scale_path.map(time);
		if (animation.use_rotation)
			transform.rotation = rotation_path.map(time);

		process_custom_animation(animation, time);
		apply_transform(transform);
	}

	private void finish_animation(WorldObjectAnimation animation)
	{
		remove_animation(animation);
	}

	protected virtual void start_custom_animation(WorldObjectAnimation animation, DeltaArgs args) {}
	protected virtual void process_custom_animation(WorldObjectAnimation animation, float time) {}

	public void set_parent_transform(Transform transform)
	{
		
	}

	protected abstract void apply_transform(Transform transform);
	protected abstract void add_object(RenderScene3D scene);

	public Transform transform { get; private set; }
}