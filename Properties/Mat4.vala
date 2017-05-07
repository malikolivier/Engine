public class Mat4
{
    private Vec4 v1;
    private Vec4 v2;
    private Vec4 v3;
    private Vec4 v4;
    
    // Caching for Optimization
    private Mat4? inverse_matrix;
    private float[]? data;

    public Mat4()
    {
        v1 = Vec4(1, 0, 0, 0);
		v2 = Vec4(0, 1, 0, 0);
        v3 = Vec4(0, 0, 1, 0);
        v4 = Vec4(0, 0, 0, 1);
        identity = true;
    }

    public Mat4.with_array(float *a)
    {
        v1 = Vec4(a[ 0], a[ 1], a[ 2], a[ 3]);
        v2 = Vec4(a[ 4], a[ 5], a[ 6], a[ 7]);
        v3 = Vec4(a[ 8], a[ 9], a[10], a[11]);
        v4 = Vec4(a[12], a[13], a[14], a[15]);
        check_is_identity();
    }

    public Mat4.with_vecs(Vec4 v1, Vec4 v2, Vec4 v3, Vec4 v4)
    {
        this.v1 = v1;
        this.v2 = v2;
        this.v3 = v3;
        this.v4 = v4;
        check_is_identity();
    }

    public Mat4.empty()
    {
        identity = false;
    }

    private void check_is_identity()
    {
        identity =
        (
            v1.x == 1 &&
            v1.y == 0 &&
            v1.z == 0 &&
            v1.w == 0 &&
            v2.x == 0 &&
            v2.y == 1 &&
            v2.z == 0 &&
            v2.w == 0 &&
            v3.x == 0 &&
            v3.y == 0 &&
            v3.z == 1 &&
            v3.w == 0 &&
            v4.x == 0 &&
            v4.y == 0 &&
            v4.z == 0 &&
            v4.w == 1 &&
        );
    }

    public Mat4? inverse()
    {
        if (inverse_matrix != null)
            return inverse_matrix;
        
        if (is_identity)
            return this;

        float mat[16], inv[16];

        Vec4 *v = (Vec4*)mat;
        v[0] = v1;
        v[1] = v2;
        v[2] = v3;
        v[3] = v4;

        return inverse_matrix = (gluInvertMatrix(mat, inv) ? new Mat4.with_array(inv) : new Mat4.empty());
    }

    public Mat4 transpose()
    {
        if (identity)
            return this;
        
        Vec4 v1 = this.col(0);
        Vec4 v2 = this.col(1);
        Vec4 v3 = this.col(2);
        Vec4 v4 = this.col(3);

        return new Mat4.with_vecs(v1, v2, v3, v4);
    }

    // this*mat
    public Mat4 mul_mat(Mat4 mat)
    {
        if (identity)
            return mat;
        if (mat.identity)
            return this;
        
        Vec4 vec1 =
        {
            v1.dot(mat.col(0)),
            v1.dot(mat.col(1)),
            v1.dot(mat.col(2)),
            v1.dot(mat.col(3))
        };

        Vec4 vec2 =
        {
            v2.dot(mat.col(0)),
            v2.dot(mat.col(1)),
            v2.dot(mat.col(2)),
            v2.dot(mat.col(3))
        };

        Vec4 vec3 =
        {
            v3.dot(mat.col(0)),
            v3.dot(mat.col(1)),
            v3.dot(mat.col(2)),
            v3.dot(mat.col(3))
        };

        Vec4 vec4 =
        {
            v4.dot(mat.col(0)),
            v4.dot(mat.col(1)),
            v4.dot(mat.col(2)),
            v4.dot(mat.col(3))
        };

        return new Mat4.with_vecs(vec1, vec2, vec3, vec4);
    }

    public Vec4 mul_vec(Vec4 vec)
    {
        return
        {
            v1.dot(vec),
            v2.dot(vec),
            v3.dot(vec),
            v4.dot(vec)
        };
    }

    public Vec4 col(int c)
    {
        return
        {
            ((float*)(&v1))[c],
            ((float*)(&v2))[c],
            ((float*)(&v3))[c],
            ((float*)(&v4))[c]
        };
    }

    public Vec4 row(int i)
    {
             if (i == 0) return v1;
        else if (i == 1) return v2;
        else if (i == 2) return v3;
        else             return v4;
    }

    public Vec3 get_position_vec3()
    {
        return Vec3(v4.x, v4.y, v4.z);
    }

    public Vec4 get_position_vec4()
    {
        return v4;
    }

    public Vec3 get_scale_vec3()
    {
        return Vec3(v1.x, v2.y, v3.z);
    }

    public Vec4 get_scale_vec4()
    {
        return Vec3(v1.x, v2.y, v3.z, v4.w);
    }

    public Quat get_rotation_quat()
    {
        float w = Math.sqrtf(Math.fmaxf(0, 1 + v1.x + v2.y + v3.z)) / 2;
        float x = Math.sqrtf(Math.fmaxf(0, 1 + v1.x - v2.y - v3.z)) / 2;
        float y = Math.sqrtf(Math.fmaxf(0, 1 - v1.x + v2.y - v3.z)) / 2;
        float z = Math.sqrtf(Math.fmaxf(0, 1 - v1.x - v2.y + v3.z)) / 2;
        x *= Calculations.sign(x * (v3.y - v2.z));
        y *= Calculations.sign(y * (v1.z - v3.x));
        z *= Calculations.sign(z * (v2.x - v1.y));

        return Quat.vals(w, x, y, z);
    }

    public float[] get_data()
    {
        if (data != null)
            return data;

        data = new float[16];
        Vec4 *v = (Vec4*)data;
        v[0] = v1;
        v[1] = v2;
        v[2] = v3;
        v[3] = v4;

        return data;
    }

    public float get(int i)
    {
        Vec4 v = {};
        int a = i / 4;
             if (a == 0) v = v1;
        else if (a == 1) v = v2;
        else if (a == 2) v = v3;
        else if (a == 3) v = v4;
        return v[i % 4];
    }

    // From Mesa 3D Graphics Library
    private static bool gluInvertMatrix(float *m, float *invOut)
    {
        float inv[16], det;
        int i;

        inv[0] = m[5]  * m[10] * m[15] -
                 m[5]  * m[11] * m[14] -
                 m[9]  * m[6]  * m[15] +
                 m[9]  * m[7]  * m[14] +
                 m[13] * m[6]  * m[11] -
                 m[13] * m[7]  * m[10];

        inv[4] = -m[4]  * m[10] * m[15] +
                  m[4]  * m[11] * m[14] +
                  m[8]  * m[6]  * m[15] -
                  m[8]  * m[7]  * m[14] -
                  m[12] * m[6]  * m[11] +
                  m[12] * m[7]  * m[10];

        inv[8] = m[4]  * m[9] * m[15] -
                 m[4]  * m[11] * m[13] -
                 m[8]  * m[5] * m[15] +
                 m[8]  * m[7] * m[13] +
                 m[12] * m[5] * m[11] -
                 m[12] * m[7] * m[9];

        inv[12] = -m[4]  * m[9] * m[14] +
                   m[4]  * m[10] * m[13] +
                   m[8]  * m[5] * m[14] -
                   m[8]  * m[6] * m[13] -
                   m[12] * m[5] * m[10] +
                   m[12] * m[6] * m[9];

        inv[1] = -m[1]  * m[10] * m[15] +
                  m[1]  * m[11] * m[14] +
                  m[9]  * m[2] * m[15] -
                  m[9]  * m[3] * m[14] -
                  m[13] * m[2] * m[11] +
                  m[13] * m[3] * m[10];

        inv[5] = m[0]  * m[10] * m[15] -
                 m[0]  * m[11] * m[14] -
                 m[8]  * m[2] * m[15] +
                 m[8]  * m[3] * m[14] +
                 m[12] * m[2] * m[11] -
                 m[12] * m[3] * m[10];

        inv[9] = -m[0]  * m[9] * m[15] +
                  m[0]  * m[11] * m[13] +
                  m[8]  * m[1] * m[15] -
                  m[8]  * m[3] * m[13] -
                  m[12] * m[1] * m[11] +
                  m[12] * m[3] * m[9];

        inv[13] = m[0]  * m[9] * m[14] -
                  m[0]  * m[10] * m[13] -
                  m[8]  * m[1] * m[14] +
                  m[8]  * m[2] * m[13] +
                  m[12] * m[1] * m[10] -
                  m[12] * m[2] * m[9];

        inv[2] = m[1]  * m[6] * m[15] -
                 m[1]  * m[7] * m[14] -
                 m[5]  * m[2] * m[15] +
                 m[5]  * m[3] * m[14] +
                 m[13] * m[2] * m[7] -
                 m[13] * m[3] * m[6];

        inv[6] = -m[0]  * m[6] * m[15] +
                  m[0]  * m[7] * m[14] +
                  m[4]  * m[2] * m[15] -
                  m[4]  * m[3] * m[14] -
                  m[12] * m[2] * m[7] +
                  m[12] * m[3] * m[6];

        inv[10] = m[0]  * m[5] * m[15] -
                  m[0]  * m[7] * m[13] -
                  m[4]  * m[1] * m[15] +
                  m[4]  * m[3] * m[13] +
                  m[12] * m[1] * m[7] -
                  m[12] * m[3] * m[5];

        inv[14] = -m[0]  * m[5] * m[14] +
                   m[0]  * m[6] * m[13] +
                   m[4]  * m[1] * m[14] -
                   m[4]  * m[2] * m[13] -
                   m[12] * m[1] * m[6] +
                   m[12] * m[2] * m[5];

        inv[3] = -m[1] * m[6] * m[11] +
                  m[1] * m[7] * m[10] +
                  m[5] * m[2] * m[11] -
                  m[5] * m[3] * m[10] -
                  m[9] * m[2] * m[7] +
                  m[9] * m[3] * m[6];

        inv[7] = m[0] * m[6] * m[11] -
                 m[0] * m[7] * m[10] -
                 m[4] * m[2] * m[11] +
                 m[4] * m[3] * m[10] +
                 m[8] * m[2] * m[7] -
                 m[8] * m[3] * m[6];

        inv[11] = -m[0] * m[5] * m[11] +
                   m[0] * m[7] * m[9] +
                   m[4] * m[1] * m[11] -
                   m[4] * m[3] * m[9] -
                   m[8] * m[1] * m[7] +
                   m[8] * m[3] * m[5];

        inv[15] = m[0] * m[5] * m[10] -
                  m[0] * m[6] * m[9] -
                  m[4] * m[1] * m[10] +
                  m[4] * m[2] * m[9] +
                  m[8] * m[1] * m[6] -
                  m[8] * m[2] * m[5];

        det = m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8] + m[3] * inv[12];

        if (det == 0)
            return false;

        det = 1 / det;

        for (i = 0; i < 16; i++)
            invOut[i] = inv[i] * det;

        return true;
    }

    public bool identity { get; private set; }
}
