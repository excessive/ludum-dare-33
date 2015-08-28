varying vec3 f_normal;

#ifdef VERTEX
	attribute vec3 VertexNormal;
	attribute vec4 VertexWeight;
	attribute vec4 VertexBone; // used as ints!

	uniform mat4 u_view, u_model, u_projection;
	uniform mat4 u_bone_matrices[128]; // this is why I want UBOs...
	uniform int	 u_skinning;

	mat4 getDeformMatrix() {
		if (u_skinning != 0) {
			// *255 because byte data is normalized against our will.
			return u_bone_matrices[int(VertexBone.x*255.0)] * VertexWeight.x +
				u_bone_matrices[int(VertexBone.y*255.0)] * VertexWeight.y +
				u_bone_matrices[int(VertexBone.z*255.0)] * VertexWeight.z +
				u_bone_matrices[int(VertexBone.w*255.0)] * VertexWeight.w;
		}
		return mat4(1.0);
	}

	vec4 position(mat4 mvp, vec4 v_position) {
		f_normal = (u_model * vec4(VertexNormal, 1.0)).xyz;
		return u_projection * u_view * u_model * getDeformMatrix() * v_position;
	}
#endif

#ifdef PIXEL
	const float near = 0.1;
	const float far  = 100.0;
	const vec4 sky_color = vec4(0.025, 0.2, 0.35, 1.0);
	uniform int no_fade;

	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
		float depth = 1.0 / gl_FragCoord.w;
		float scaled = (depth - near) / (far - near);

		vec4 out_color = texture2D(texture, texture_coords);
		out_color.a = 1.0;
		out_color *= color;

		if (no_fade != 0) {
			return out_color;
		}
		return mix(out_color, sky_color, min(scaled, 1.0));
	}
#endif
