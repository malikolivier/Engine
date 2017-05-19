public class Calculations
{
    private Calculations(){}

    public static Vec3 rotate(Vec3 origin, Vec3 rotation, Vec3 offset)
    {
        Vec3 point = offset;
        point = rotate_x(origin, rotation.x, point);
        point = rotate_y(origin, rotation.y, point);
        point = rotate_z(origin, rotation.z, point);
        return point;
    }

    public static Vec3 rotate_x(Vec3 origin, float rotation, Vec3 offset)
    {
        if (rotation == 0)
            return offset;

        float c = (float)Math.cos(rotation * Math.PI);
        float s = (float)Math.sin(rotation * Math.PI);

        Vec3 p = offset.minus(origin);

        p = Vec3
        (
            p.x,
            p.y * c - p.z * s,
            p.y * s + p.z * c
        );

        return p.plus(origin);
    }

    public static Vec3 rotate_y(Vec3 origin, float rotation, Vec3 offset)
    {
        if (rotation == 0)
            return offset;

        float c = (float)Math.cos(rotation * Math.PI);
        float s = (float)Math.sin(rotation * Math.PI);

        Vec3 p = offset.minus(origin);

        p = Vec3
        (
            p.z * s + p.x * c,
            p.y,
            p.z * c - p.x * s
        );

        return p.plus(origin);
    }

    public static Vec3 rotate_z(Vec3 origin, float rotation, Vec3 offset)
    {
        if (rotation == 0)
            return offset;

        float c = (float)Math.cos(rotation * Math.PI);
        float s = (float)Math.sin(rotation * Math.PI);

        Vec3 p = offset.minus(origin);

        p = Vec3
        (
            p.x * c - p.y * s,
            p.x * s + p.y * c,
            p.z
        );

        return p.plus(origin);
    }

    public static Vec3 get_ray(Mat4 projection_matrix, Mat4 view_matrix, Vec2i point, Size2i size)
    {
        float aspect = (float)size.width / size.height;
        float x = -(1 - (float)point.x / size.width  * 2) * aspect;
        float y = -(1 - (float)point.y / size.height * 2) * aspect;

        // TODO: Why is this the unview matrix?
        Mat4 unview_matrix = view_matrix.mul_mat(projection_matrix.inverse());
        Vec4 vec = Vec4(x, y, 0, 1);
        Vec4 ray_dir = unview_matrix.mul_vec(vec);

        return Vec3(ray_dir.x, ray_dir.y, ray_dir.z).normalize();
    }

    public static float get_collision_distance
    (
        Vec3 ray_origin,
        Vec3 ray_direction,
        Vec3 model_obb,
        Mat4 model_matrix
    )
    {
        return get_collision_distance_box(ray_origin, ray_direction, model_obb.mul_scalar(-0.5f), model_obb.mul_scalar(0.5f), model_matrix);
    }

    public static float get_collision_distance_box
    (
        Vec3 ray_origin,        // Ray origin, in world space
        Vec3 ray_direction,     // Ray direction (NOT target position!), in world space. Must be normalize()'d.
        Vec3 aabb_min,          // Minimum X,Y,Z coords of the mesh when not transformed at all.
        Vec3 aabb_max,          // Maximum X,Y,Z coords. Often aabb_min*-1 if your mesh is centered, but it's not always the case.
        Mat4 model_matrix       // Transformation applied to the mesh (which will thus be also applied to its bounding box)
    )
    {
        // Intersection method from Real-Time Rendering and Essential Mathematics for Games
        // Licensed under WTF public license (the best license)

        float tMin = 0.0f;
        float tMax = 100000.0f;

        Vec3 OBBposition_worldspace = Vec3(model_matrix[12], model_matrix[13], model_matrix[14]);
        Vec3 delta = OBBposition_worldspace.minus(ray_origin);

        // Test intersection with the 2 planes perpendicular to the OBB's X axis
        {
            Vec3 xaxis = Vec3(model_matrix[0], model_matrix[1], model_matrix[2]);
            float e = xaxis.dot(delta);
            float f = ray_direction.dot(xaxis);
            float l = xaxis.length();
            l *= l;

            if (Math.fabsf(f) > 0.001f)
            {
                // Standard case
                float t1 = (e + aabb_min.x * l) / f; // Intersection with the "left" plane
                float t2 = (e + aabb_max.x * l) / f; // Intersection with the "right" plane
                // t1 and t2 now contain distances betwen ray origin and ray-plane intersections

                // We want t1 to represent the nearest intersection,
                // so if it's not the case, invert t1 and t2
                if (t1 > t2)
                {
                    // swap t1 and t2
                    float w = t1;
                    t1 = t2;
                    t2 = w;
                }

                // tMax is the nearest "far" intersection (amongst the X,Y and Z planes pairs)
                if (t2 < tMax)
                    tMax = t2;
                // tMin is the farthest "near" intersection (amongst the X,Y and Z planes pairs)
                if (t1 > tMin)
                    tMin = t1;

                // And here's the trick :
                // If "far" is closer than "near", then there is NO intersection.
                // See the images in the tutorials for the visual explanation.
                if (tMax < tMin)
                    return -1;
            }
            else
            {
                // Rare case : the ray is almost parallel to the planes, so they don't have any "intersection"
                if (-e + aabb_min.x > 0.0f || -e + aabb_max.x < 0.0f)
                    return -1;
            }
        }

        // Test intersection with the 2 planes perpendicular to the OBB's Y axis
        // Exactly the same thing as above.
        {
            Vec3 yaxis = Vec3(model_matrix[4], model_matrix[5], model_matrix[6]);
            float e = yaxis.dot(delta);
            float f = ray_direction.dot(yaxis);
            float l = yaxis.length();
            l *= l;

            if (Math.fabsf(f) > 0.001f)
            {
                float t1 = (e + aabb_min.y * l) / f;
                float t2 = (e + aabb_max.y * l) / f;

                if (t1 > t2)
                {
                    float w = t1;
                    t1 = t2;
                    t2 = w;
                }

                if (t2 < tMax)
                    tMax = t2;
                if (t1 > tMin)
                    tMin = t1;

                if (tMax < tMin)
                    return -1;

            }
            else
            {
                if (-e + aabb_min.y > 0.0f || -e + aabb_max.y < 0.0f)
                    return -1;
            }
        }

        // Test intersection with the 2 planes perpendicular to the OBB's Z axis
        // Exactly the same thing as above.
        {
            Vec3 zaxis = Vec3(model_matrix[8], model_matrix[9], model_matrix[10]);
            float e = zaxis.dot(delta);
            float f = ray_direction.dot(zaxis);
            float l = zaxis.length();
            l *= l;

            if (Math.fabsf(f) > 0.001f)
            {
                float t1 = (e + aabb_min.z * l) / f;
                float t2 = (e + aabb_max.z * l) / f;

                if (t1 > t2)
                {
                    float w = t1;
                    t1 = t2;
                    t2 = w;
                }

                if (t2 < tMax)
                    tMax = t2;
                if (t1 > tMin)
                    tMin = t1;

                if (tMax < tMin)
                    return -1;

            }
            else
            {
                if (-e + aabb_min.z > 0.0f || -e + aabb_max.z < 0.0f)
                    return -1;
            }
        }

        return tMin;
    }

    public static Mat4 rotation_matrix_quat(Quat quat)
    {
        float x = quat.x;
        float y = quat.y;
        float z = quat.z;
        float w = quat.w;

        float x2 = x + x;
        float y2 = y + y;
        float z2 = z + z;
        float xx = x * x2;
        float xy = x * y2;
        float xz = x * z2;
        float yy = y * y2;
        float yz = y * z2;
        float zz = z * z2;
        float wx = w * x2;
        float wy = w * y2;
        float wz = w * z2;

        float m[16] =
        {
            1 - (yy + zz),       xy - wz,       xz + wy, 0,
                  xy + wz, 1 - (xx + zz),       yz - wx, 0,
                  xz - wy,       yz + wx, 1 - (xx + yy), 0,
                        0,             0,             0, 1
        };

        return new Mat4.with_array(m);
    }

    public static Mat4 translation_matrix(Vec3 vec)
    {
        float[] vals =
        {
            1,    0,    0, vec.x,
            0,    1,    0, vec.y,
            0,    0,    1, vec.z,
            0,    0,    0,     1
        };

        return new Mat4.with_array(vals);
    }

    public static Mat4 scale_matrix(Vec3 vec)
    {
        float[] vals =
        {
            vec.x, 0, 0, 0,
            0, vec.y, 0, 0,
            0, 0, vec.z, 0,
            0, 0,     0, 1
        };

        return new Mat4.with_array(vals);
    }

    public static Mat4 get_model_matrix(Vec3 translation, Vec3 scale, Quat rotation)
    {
        Mat4 t = translation_matrix(translation);
        Mat4 s = scale_matrix(scale);
        Mat4 r = rotation_matrix_quat(rotation);

        return t.mul_mat(r).mul_mat(s);
    }

    public static Mat3 rotation_matrix_3(float angle)
    {
        float s = (float)Math.sin(angle);
        float c = (float)Math.cos(angle);

        float[] vals =
        {
             c, s, 0,
            -s, c, 0,
             0, 0, 1
        };

        return new Mat3.with_array(vals);
    }

    public static Mat3 translation_matrix_3(Vec2 vec)
    {
        float[] vals =
        {
            1,     0,     0,
            0,     1,     0,
            vec.x, vec.y, 1
        };

        return new Mat3.with_array(vals);
    }

    public static Mat3 scale_matrix_3(Size2 vec)
    {
        float[] vals =
        {
            vec.width,  0, 0,
            0, vec.height, 0,
            0,          0, 1
        };

        return new Mat3.with_array(vals);
    }

    public static Mat3 get_model_matrix_3(Vec2 position, float rotation, Size2 scale, float aspect)
    {
        Mat3 s = scale_matrix_3(scale);
        Mat3 r = rotation_matrix_3(rotation * (float)Math.PI);
        Mat3 a = scale_matrix_3(Size2(1, aspect)); // Fix aspect after rotation
        Mat3 p = translation_matrix_3(position);

        return s.mul_mat(r).mul_mat(a).mul_mat(p);
    }

    public static int sign(float n)
    {
        if (n > 0) return 1;
        if (n < 0) return -1;
        return 0;
    }
}
