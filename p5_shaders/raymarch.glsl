varying vec4 vertTexCoord;

vec3 cameraOrigin = vec3(2.0, 2.0, 2.0);
vec3 cameraTarget = vec3(0.0, 0.0, 0.0);
vec3 upDirection = vec3(0.0, 1.0, 0.0);

const int MAX_ITER = 100;
const float MAX_DIST = 200.0;
const float EPSILON = 0.001;

uniform float time;

mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}

mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

mat3 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
}

float plane(vec3 pos, vec4 n){
	// n must be normalized
  	return dot(pos, n.xyz) + n.w;
}

float sphere(vec3 pos, float radius){
	return length(pos) - radius;
}

float box(vec3 pos, vec3 size){
    return length(max(abs(pos) - size, 0.0));
}

float distfunc(vec3 pos){
	float d1 = sphere(pos, 1.1);
	float d2 = box(pos, vec3(1.0, 1.0, 1.0));

	vec3 rotatePoint = rotateX(-time) * pos;
	float d3 = plane(rotatePoint, vec4(0.1));
	//float d3 = box(rotatePoint, vec3(1.0, 1.0, 1.0));

	float combined = min(d1, d2);
	float intersection = max(d1, d2);
	float subtracted = max(-d1, d2);

	return d3;
}

void main(){
	vec3 cameraDir = normalize(cameraTarget - cameraOrigin);
	vec3 cameraRight = normalize(cross(upDirection, cameraOrigin));
	vec3 cameraUp = cross(cameraDir, cameraRight);

	vec2 screenPos = -1.0 + 2.0 * vertTexCoord.xy;

	vec3 rayDir = normalize(cameraRight * screenPos.x + cameraUp * screenPos.y + cameraDir);

	////////////////////////////////////////////////////////////////////////////////////////

	float totalDist = 0.0;
	vec3 pos = cameraOrigin;
	float dist = EPSILON;

	//pos.z += time;
	//pos.x += time;

	for (int i = 0; i < MAX_ITER; i++){
		if (dist < EPSILON || totalDist > MAX_DIST)
			break;

		dist = distfunc(pos);
		totalDist += dist;
		pos += dist * rayDir; 
	}

	if (dist < EPSILON){
		//calculate lighting gradient
		vec2 eps = vec2(0.0, EPSILON);
		vec3 normal = normalize(vec3(
			distfunc(pos + eps.yxx) - distfunc(pos - eps.yxx),
			distfunc(pos + eps.xyx) - distfunc(pos - eps.xyx),
			distfunc(pos + eps.xxy) - distfunc(pos - eps.xyy)));

		float diffuse = max(0.0, dot(-rayDir, normal));
		float specular = pow(diffuse, 32.0);

		vec3 color = vec3(diffuse + specular);
		gl_FragColor = vec4(color, 1.0);
	} else {
		gl_FragColor = vec4(0.0);
	}

}