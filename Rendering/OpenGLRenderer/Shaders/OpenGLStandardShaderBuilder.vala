public class OpenGLStandardShaderBuilder : OpenGLShaderBuilder
{
    public OpenGLStandardShaderBuilder(bool high_quality, int max_lights = 2)
    {
        OpenGLShaderDefine max_lights_define = new OpenGLShaderDefine("MAX_LIGHTS", max_lights.to_string());

        OpenGLShaderDefine blend_color_define = new OpenGLShaderDefine("BLEND_COLOR", "1");
        OpenGLShaderDefine blend_texture_define = new OpenGLShaderDefine("BLEND_TEXTURE", "2");
        OpenGLShaderDefine blend_with_material_multiplier_define = new OpenGLShaderDefine("BLEND_WITH_MATERIAL_MULTIPLIER", "3");
        OpenGLShaderDefine blend_without_material_multiplier_define = new OpenGLShaderDefine("BLEND_WITHOUT_MATERIAL_MULTIPLIER", "4");
        OpenGLShaderDefine blend_label_define = new OpenGLShaderDefine("BLEND_LABEL", "5");

        OpenGLShaderUniform projection_transform_uniform = new OpenGLShaderUniform("projection_transform", OpenGLShaderPrimitiveType.MAT4);
        OpenGLShaderUniform view_transform_uniform = new OpenGLShaderUniform("view_transform", OpenGLShaderPrimitiveType.MAT4);
        OpenGLShaderUniform model_transform_uniform = new OpenGLShaderUniform("model_transform", OpenGLShaderPrimitiveType.MAT4);
        //OpenGLShaderUniform un_projection_transform_uniform = new OpenGLShaderUniform("un_projection_transform", OpenGLShaderPrimitiveType.MAT4);
        OpenGLShaderUniform un_view_transform_uniform = new OpenGLShaderUniform("un_view_transform", OpenGLShaderPrimitiveType.MAT4);
        OpenGLShaderUniform un_model_transform_uniform = new OpenGLShaderUniform("un_model_transform", OpenGLShaderPrimitiveType.MAT4);

        OpenGLShaderStruct light_source_struct = new OpenGLShaderStruct("lightSourceParameters",
        {
            new OpenGLShaderProperty("position", OpenGLShaderPrimitiveType.VEC3),
            new OpenGLShaderProperty("color", OpenGLShaderPrimitiveType.VEC3),
            new OpenGLShaderProperty("intensity", OpenGLShaderPrimitiveType.FLOAT)
        });
        

        OpenGLShaderUniform light_count_uniform = new OpenGLShaderUniform("light_count", OpenGLShaderPrimitiveType.INT);
        OpenGLShaderUniform light_source_uniform = new OpenGLShaderUniform("light_source", OpenGLShaderPrimitiveType.CUSTOM)
        {
            array = max_lights_define.name,
            custom_type = light_source_struct.name,
            dependencies = { light_source_struct, max_lights_define }
        };

        OpenGLShaderUniform alpha_uniform = new OpenGLShaderUniform("alpha", OpenGLShaderPrimitiveType.FLOAT);
        OpenGLShaderUniform specular_exponent_uniform = new OpenGLShaderUniform("specular_exponent", OpenGLShaderPrimitiveType.FLOAT);
        OpenGLShaderUniform use_texture_uniform = new OpenGLShaderUniform("use_texture", OpenGLShaderPrimitiveType.BOOL);
        OpenGLShaderUniform tex_uniform = new OpenGLShaderUniform("tex", OpenGLShaderPrimitiveType.SAMPLER2D);

        OpenGLShaderUniform ambient_material_multiplier_uniform = new OpenGLShaderUniform("ambient_material_multiplier", OpenGLShaderPrimitiveType.FLOAT);
        OpenGLShaderUniform ambient_color_uniform = new OpenGLShaderUniform("ambient_color", OpenGLShaderPrimitiveType.VEC4);
        OpenGLShaderUniform diffuse_material_multiplier_uniform = new OpenGLShaderUniform("diffuse_material_multiplier", OpenGLShaderPrimitiveType.FLOAT);
        OpenGLShaderUniform diffuse_color_uniform = new OpenGLShaderUniform("diffuse_color", OpenGLShaderPrimitiveType.VEC4);
        OpenGLShaderUniform specular_material_multiplier_uniform = new OpenGLShaderUniform("specular_material_multiplier", OpenGLShaderPrimitiveType.FLOAT);
        OpenGLShaderUniform specular_color_uniform = new OpenGLShaderUniform("specular_color", OpenGLShaderPrimitiveType.VEC4);
        
        OpenGLShaderVarying frag_normal_varying = new OpenGLShaderVarying("frag_normal", OpenGLShaderPrimitiveType.VEC3);
        OpenGLShaderVarying frag_camera_normal_varying = new OpenGLShaderVarying("frag_camera_normal", OpenGLShaderPrimitiveType.VEC3);

        OpenGLShaderVarying diffuse_strength_varying = new OpenGLShaderVarying("diffuse_strength", OpenGLShaderPrimitiveType.VEC4);
        OpenGLShaderVarying specular_strength_varying = new OpenGLShaderVarying("specular_strength", OpenGLShaderPrimitiveType.VEC4);

        OpenGLShaderVarying light_normals_varying = new OpenGLShaderVarying("light_normals", OpenGLShaderPrimitiveType.VEC3)
        { array = max_lights_define.name, dependencies = { max_lights_define } };
        OpenGLShaderVarying light_intensity_varying = new OpenGLShaderVarying("light_intensity", OpenGLShaderPrimitiveType.FLOAT)
        { array = max_lights_define.name, dependencies = { max_lights_define } };
        OpenGLShaderVarying light_colors_varying = new OpenGLShaderVarying("light_colors", OpenGLShaderPrimitiveType.VEC3)
        { array = max_lights_define.name, dependencies = { max_lights_define } };
        
        OpenGLShaderVarying frag_texture_coord_varying = new OpenGLShaderVarying("frag_texture_coord", OpenGLShaderPrimitiveType.VEC2);
        
        OpenGLShaderAttribute position_attribute = new OpenGLShaderAttribute("position", OpenGLShaderPrimitiveType.VEC4);
        OpenGLShaderAttribute texture_coord_attribute = new OpenGLShaderAttribute("texture_coord", OpenGLShaderPrimitiveType.VEC3);
        OpenGLShaderAttribute normal_attribute = new OpenGLShaderAttribute("normal", OpenGLShaderPrimitiveType.VEC3);

        OpenGLShaderCodeBlock calculate_lighting_factor_code = new OpenGLShaderCodeBlock(calculate_lighting_factor_code_string)
        {
            dependencies = { frag_normal_varying, frag_camera_normal_varying, light_intensity_varying, light_normals_varying, light_colors_varying,
            specular_exponent_uniform, light_count_uniform }
        };

        OpenGLShaderFunction calculate_lighting_factor_function = new OpenGLShaderFunction("calculate_lighting_factor", OpenGLShaderPrimitiveType.VOID);
        calculate_lighting_factor_function.parameters =
        {
            new OpenGLShaderProperty("diffuse_out", OpenGLShaderPrimitiveType.VEC4) { direction = OpenGLShaderPropertyDirection.OUT },
            new OpenGLShaderProperty("specular_out", OpenGLShaderPrimitiveType.VEC4) { direction = OpenGLShaderPropertyDirection.OUT },
        };
        calculate_lighting_factor_function.add_code(calculate_lighting_factor_code);

        OpenGLShaderCodeBlock base_color_blend_code = new OpenGLShaderCodeBlock(base_color_blend_code_string)
        {
            dependencies = { blend_color_define, blend_texture_define,
                blend_with_material_multiplier_define, blend_without_material_multiplier_define, blend_label_define }
        };

        OpenGLShaderFunction base_color_blend_function = new OpenGLShaderFunction("base_color_blend", OpenGLShaderPrimitiveType.VEC4)
        {
            parameters =
            {
                new OpenGLShaderProperty("color", OpenGLShaderPrimitiveType.VEC4),
                new OpenGLShaderProperty("texture_color", OpenGLShaderPrimitiveType.VEC4),
                new OpenGLShaderProperty("material_multiplier", OpenGLShaderPrimitiveType.FLOAT),
                new OpenGLShaderProperty("type", OpenGLShaderPrimitiveType.INT)
            }
        };
        base_color_blend_function.add_code(base_color_blend_code);

        OpenGLShaderCodeBlock vertex_start_code = new OpenGLShaderCodeBlock(vertex_start_code_string)
        {
            dependencies = { position_attribute, texture_coord_attribute, normal_attribute,
            light_normals_varying, light_intensity_varying, light_colors_varying, frag_texture_coord_varying, frag_normal_varying, frag_camera_normal_varying,
            projection_transform_uniform, view_transform_uniform, model_transform_uniform,
                un_view_transform_uniform, un_model_transform_uniform, light_count_uniform, light_source_uniform,
            light_source_struct }
        };

        OpenGLShaderCodeBlock fragment_start_code = new OpenGLShaderCodeBlock(fragment_start_code_string)
        {
            dependencies = { frag_texture_coord_varying,
            alpha_uniform, tex_uniform, use_texture_uniform, ambient_material_multiplier_uniform, ambient_color_uniform,
                diffuse_material_multiplier_uniform, diffuse_color_uniform, specular_material_multiplier_uniform, specular_color_uniform,
            base_color_blend_function }
        };

        OpenGLShaderCodeBlock fragment_end_code = new OpenGLShaderCodeBlock(fragment_end_code_string);
        OpenGLShaderCodeBlock define_local_vars_code = new OpenGLShaderCodeBlock(define_local_vars_code_string);

        OpenGLShaderCodeBlock do_calculate_lighting_code = new OpenGLShaderCodeBlock(do_calculate_lighting_code_string)
        { dependencies = { calculate_lighting_factor_function } };

        if (high_quality)
            do_calculate_lighting_code.add_dependency(define_local_vars_code);
        else
        {
            do_calculate_lighting_code.add_dependency(diffuse_strength_varying);
            do_calculate_lighting_code.add_dependency(specular_strength_varying);
            fragment_main.add_dependency(diffuse_strength_varying);
            fragment_main.add_dependency(specular_strength_varying);
        }

        add_vertex_block(vertex_start_code);
        if (!high_quality) add_vertex_block(do_calculate_lighting_code);

        add_fragment_block(fragment_start_code);
        if (high_quality) add_fragment_block(do_calculate_lighting_code);
        add_fragment_block(fragment_end_code);
    }

    private string calculate_lighting_factor_code_string = """
        vec4 diffuse_in = vec4(1.0);
        vec4 specular_in = vec4(1.0);
        
        float blend_factor = 0.0;//0.005;
        float constant_factor = 0.01;
        float linear_factor = 0.8;
        float quadratic_factor = 0.5;
            
        vec3 normal = normalize(frag_normal);
        
        vec3 diffuse = vec3(0);//diffuse_in;//out_color.xyz * 0.02;
        vec3 specular = vec3(0);
        vec3 c = diffuse_in.xyz;//out_color.xyz;
        
        for (int i = 0; i < light_count; i++)
        {
            float intensity = light_intensity[i];
            
            float lnlen = max(length(light_normals[i]), 1);
            vec3 ln = normalize(light_normals[i]);
            vec3 cm = normalize(frag_camera_normal);
            
            float d = max(dot(normal, ln) / 1, 0);
            float plus = 0;
            plus += d * constant_factor;
            plus += d / lnlen * linear_factor;
            plus += d / pow(lnlen, 2) * quadratic_factor;
            
            diffuse += (c * (1-blend_factor) + light_colors[i] * blend_factor) * plus * intensity;
            
            if (dot(ln, normal) > 0) // Only reflect on the correct side
            {
                float s = max(dot(cm, reflect(-ln, normal)), 0);
                float spec = pow(s, specular_exponent);
                
                float p = 0;
                p += spec * constant_factor;
                p += spec / lnlen * linear_factor;
                p += spec / pow(lnlen, 2) * quadratic_factor;
                
                p = max(p, 0) * intensity;
                
                specular += (light_colors[i] * (1-blend_factor) * 0 + specular_in.xyz/* * blend_factor*/) * p;
            }
        }
        
        float dist = max(pow(length(frag_camera_normal) / 5, 1.0) / 10, 1);
        diffuse /= dist;
        specular /= dist;
        
        diffuse_out = vec4(diffuse, 1.0);
        specular_out = vec4(specular, 1.0);
    """;


    private string base_color_blend_code_string = """
        if (type == BLEND_COLOR)
            return color;
        else if (type == BLEND_TEXTURE)
            return texture_color;
        else if (type == BLEND_WITH_MATERIAL_MULTIPLIER)
            return color * color.a * (1.0 - texture_color.a * material_multiplier) + texture_color * texture_color.a * material_multiplier;
        else if (type == BLEND_WITHOUT_MATERIAL_MULTIPLIER)
            return color * color.a * (1.0 - texture_color.a)                       + texture_color * texture_color.a * material_multiplier;
        else
            return vec4(0);
    """;

    private string vertex_start_code_string = """
        vec3 mod_pos = (model_transform * position).xyz;
        for (int i = 0; i < light_count; i++)
        {
            light_normals[i] = light_source[i].position - mod_pos;
            light_intensity[i] = light_source[i].intensity;
            light_colors[i] = light_source[i].color;
        }
        
        frag_texture_coord = texture_coord.xy;
        frag_normal = (vec4(normalize(normal), 1.0) * un_model_transform).xyz;
        frag_camera_normal = un_view_transform[3].xyz - mod_pos;
        gl_Position = projection_transform * view_transform * model_transform * position;
    """;

    private string do_calculate_lighting_code_string = """
        vec4 diffuse_str, specular_str;
        calculate_lighting_factor(diffuse_str, specular_str);
        diffuse_strength = diffuse_str;
        specular_strength = specular_str;
    """;

    private string fragment_start_code_string = """
    	if (alpha <= 0)
            discard;
        
        vec4 t = use_texture ? texture2D(tex, frag_texture_coord) : vec4(0);
        
        vec4  ambient = base_color_blend( ambient_color, t,  ambient_material_multiplier, BLEND_WITHOUT_MATERIAL_MULTIPLIER);
        vec4  diffuse = base_color_blend( diffuse_color, t,  diffuse_material_multiplier, BLEND_WITHOUT_MATERIAL_MULTIPLIER);
        vec4 specular = base_color_blend(specular_color, t, specular_material_multiplier, BLEND_WITH_MATERIAL_MULTIPLIER);
        
        if (ambient.a <= 0 && diffuse.a <= 0)
		    discard;
    """;

    private string define_local_vars_code_string = """
    	vec4 diffuse_strength;
    	vec4 specular_strength;
    """;

    private string fragment_end_code_string = """
    	diffuse  *= diffuse_strength;
        specular *= specular_strength;
        
        gl_FragColor = vec4(ambient.xyz + diffuse.xyz + specular.xyz, alpha);
    """;
}