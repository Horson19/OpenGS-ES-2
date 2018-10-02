//要用的值
attribute vec4 position;
attribute vec2 texCoordinate;
uniform mat4 rotateMatrix;
//传值用的
varying lowp vec2 varyTexCoord;

void main(){
    varyTexCoord = texCoordinate;
    vec4 vPos = position;
    vPos = position * rotateMatrix;
    gl_Position = vPos;
}
