// 导入必要的库
import lib-sampler.glsl
import lib-defines.glsl

//: param auto environment_rotation 
uniform float uniform_environment_rotation;

// 将环境旋转角度映射到[0, 2*pi]范围
float environment_rotation = uniform_environment_rotation * M_2PI;

// 硬编码一个全局的光源位置：
vec3 light_pos = vec3(10.0, 10.0, 10.0);

// 创建旋转矩阵
mat3 rotationMatrix = mat3(
    cos(environment_rotation), 0.0, sin(environment_rotation),
    0.0, 1.0, 0.0,
    -sin(environment_rotation), 0.0, cos(environment_rotation)
);

// 旋转光源位置
vec3 rotated_light_pos = rotationMatrix * light_pos;

// 绑定相机位置
//: param auto world_eye_position
uniform vec3 camera_pos;

// 绑定基础色
//: param auto channel_basecolor
uniform SamplerSparse basecolor_tex;

//: param auto channel_user0
uniform SamplerSparse shadow_channel;

//: param custom { "default": 0.4, "label": "Shadow Color", "widget": "color" } 
uniform vec3 u_color_shadow; 

//: param custom { "default": 0.5, "label": "Shadow Range", "min": 0.0, "max": 1.0 } 
uniform float u_slider_shadow; 

//: param custom { "default": 0, "label": "OutLine Color", "widget": "color" } 
uniform vec3 u_color_outline; 

//: param custom { "default": 0.18, "label": "Outline Thinkness", "min": 0.0, "max": 1.0 } 
uniform float u_slider_outlinethinkness; 

//: param custom { "default": true, "label": "Lighting Shadow" } 
uniform bool u_bool_shaodw;

//: param custom { "default": 0.01, "label": "Shadow Factor", "min": 0.0, "max": 0.1 } 
uniform float u_slider_ShadowFactor; 

void shade(V2F inputs)
{
    // 法线：
    vec3 N = normalize(inputs.normal);
    // 光源方向
    vec3 L = normalize(rotated_light_pos - inputs.position);
    // 观察方向
    vec3 V = normalize(camera_pos - inputs.position);

    // 根据光照方向来离散地对基础颜色进行减弱：
    float NdL = max(0.0, dot(N, L));
    vec3 color = getBaseColor(basecolor_tex, inputs.sparse_coord);

    // 采样永久阴影信息
    float permanentShadow = textureSparse(shadow_channel, inputs.sparse_coord).r; // 假设灰度值存储在红色通道

    // 应用永久阴影
    color = mix(color, u_color_shadow, permanentShadow);

    // 光照阴影处理
    float shadowTransition = u_slider_ShadowFactor; // 渐变范围，可以根据需要调整这个值来控制渐变的软硬程度
    if(u_bool_shaodw){
        float shadowFactor = smoothstep(u_slider_shadow - shadowTransition, u_slider_shadow + shadowTransition, NdL);
        color = mix(color, u_color_shadow, 1 - shadowFactor); // 在光照和阴影之间进行混合
    }

    // 边缘检测和描边
    float edge = 0.0;
    // 检测与相机的边缘
    edge += abs(dot(N, V));
    // 描边处理
    if (edge < u_slider_outlinethinkness) {
        color = u_color_outline; // 使用描边颜色
    }

    // 输出颜色
    diffuseShadingOutput(color);
}