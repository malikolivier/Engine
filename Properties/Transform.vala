public class Transform
{
	private Mat4 _matrix;
	private Vec3 _position;
	private Vec3 _scale;
	private Quat _rotation;

	public Transform()
	{
		_matrix = new Mat4();
		_scale = Vec3(1, 1, 1);
		_rotation = new Quat();
	}

	private Transform.copy_init() {}

	public Transform copy()
	{
		Transform t = new Transform.copy_init();

		t._matrix = _matrix;
		t._position = _position;
		t._scale = _scale;
		t._rotation = _rotation;
		t.dirty_matrix = dirty_matrix;
		t.dirty_position = dirty_position;
		t.dirty_scale = dirty_scale;
		t.dirty_rotation = dirty_rotation;

		return t;
	}

	public void change_parent(Transform from, Transform to)
	{
		unapply_transform(from);
		apply_transform(to);
	}

	public void apply_transform(Transform t)
	{
		matrix = t.mul_mat(matrix);
	}

	public void unapply_transform(Transform t)
	{
		matrix = t.mul_mat(t.inverse());
	}

	public Mat4 matrix
	{
		get
		{
			if (dirty_matrix)
			{
				_matrix = Calculations.get_model_matrix(_position, _scale, _rotation);
				dirty_matrix = false;
			}

			return _matrix;
		}

		set
		{
			if (_matrix.equals(value))
				return;

			dirty_matrix = false;
			dirty_position = true;
			dirty_scale = true;
			dirty_rotation = true;

			_matrix = value;
		}
	}

	public Vec3 position
	{
		get
		{
			if (dirty_position)
			{
				_position = _matrix.get_position_vec3();
				dirty_position = false;
			}

			return _position;
		}

		set
		{
			if (_position == value)
				return;
			
			// Undirty
			get_scale();
			get_rotation();
				
			dirty_matrix = true;
			dirty_position = false;

			_position = value;
		}
	}

	public Vec3 scale
	{
		get
		{
			if (dirty_scale)
			{
				_scale = _matrix.get_scale_vec3();
				dirty_scale = false;
			}

			return _scale;
		}

		set
		{
			if (_scale == value)
				return;
			
			// Undirty
			get_position();
			get_rotation();
				
			dirty_matrix = true;
			dirty_scale = false;

			_scale = value;
		}
	}

	public Quat rotation
	{
		get
		{
			if (dirty_rotation)
			{
				_rotation = _matrix.get_rotation_quat();
				dirty_rotation = false;
			}

			return _rotation;
		}

		set
		{
			if (_rotation.equals(value))
				return;
			
			// Undirty
			get_position();
			get_scale();
				
			dirty_matrix = true;
			dirty_rotation = false;

			_rotation = value;
		}
	}

	public bool dirty_matrix { get; private set; }
	public bool dirty_position { get; private set; }
	public bool dirty_scale { get; private set; }
	public bool dirty_rotation { get; private set; }
}