//
//  HSView.m
//  GLSLDemo
//
//  Created by HorsonChan on 2018/9/28.
//  Copyright © 2018年 Horson. All rights reserved.
//

/*
 不采用GLBaseEffect 使用编译连接自定义shader，用简单glsl语言来实现顶点着色器\片元着色器，并且实现图形的简单变换
 思路：
 1.创建图层
 2.创建上下文
 3.清空缓冲区
 4.设置renderBuffer，FrameBuffer
 5.开始绘制
 */

#import "HSView.h"
#import <OpenGLES/ES2/gl.h>

@interface HSView()

@property(nonatomic,strong)CAEAGLLayer *myLayer;
@property(nonatomic,strong)EAGLContext *myContext;
@property(nonatomic,assign)GLuint myColorRenderBuffer;
@property(nonatomic,assign)GLuint myColorFrameBuffer;
@property(nonatomic,assign)GLuint myProgram;

@end

@implementation HSView

- (void)layoutSubviews{
    //1.设置图层
    [self setupLayer];
    
    //2.创建上下文
    [self creatContext];
    
    //3.清空缓冲区
    [self clearFrameAndRenderBuffer];
    
    //4.设置renderBuffer
    [self setupColorRenderBuffer];
    
    //5.设置FrameBuffer
    [self setupColorFrameBuffer];
    
    //6.开始绘制
    [self renderLayer];
    
}

//6.开始绘制
-(void)renderLayer{
    //先在empty写好顶点着色器和片元着色器
    
    glClearColor(0.0f, 1.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    GLfloat scale = [[UIScreen mainScreen]scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    //编译着色器
    NSString *vertexPath = [[NSBundle mainBundle]pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fragmentPath = [[NSBundle mainBundle]pathForResource:@"shaderf" ofType:@"fsh"];
    NSLog(@"vertex shader: %@",vertexPath);
    NSLog(@"fragment shader :%@",fragmentPath);
    //加载shader
    self.myProgram = [self loadShader:vertexPath AndFragment:fragmentPath];
    //链接
    glLinkProgram(self.myProgram);
    //获取link状态
    GLint status;
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        GLchar message[512];
        glGetProgramInfoLog(self.myProgram, sizeof(message), 0, &message[0]);
        NSString *messageStr = [NSString stringWithUTF8String:message];
        NSLog(@"creat program failed!!! %@",messageStr);
        return;
    }
    
    
    glUseProgram(self.myProgram);
    
    GLfloat attArr[] = {
        0.5f,-0.5f,1.0f,   1.0f,0.0f,
        -0.5f,0.5f,1.0f,   0.0f,1.0f,
        -0.5f,-0.5f,1.0f,  0.0f,0.0f,
        0.5f,0.5f,1.0f,    1.0f,1.0f,
        -0.5f,0.5f,1.0f,   0.0f,1.0f,
        0.5f,-0.5f,1.0f,   1.0f,0.0f,
    };
    
    GLuint attributeBuffer;
    glGenBuffers(1, &attributeBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attributeBuffer);
    //读取顶点的数据到GPU
    glBufferData(GL_ARRAY_BUFFER, sizeof(attArr), attArr, GL_DYNAMIC_DRAW);
    //从程序中读一个position的位置出来
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    
    //随后开始进行顶点处理，所有的顶点数据都得从上面那步顶点加载到GPU的buffer来获取顶点数组
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    
    GLuint texCoord = glGetAttribLocation(self.myProgram, "texCoordinate");
    glEnableVertexAttribArray(texCoord);
    glVertexAttribPointer(texCoord, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
    
    //加载纹理
    [self setupTexture:@"timg"];
    
    float radians = 0 * 3.1415926 / 180.0f;
    float s = sin(radians);
    float c = cos(radians);
    
    GLfloat zRoatation[16] = {
        c,-s,0,0,
        s,c,0,0,
        0,0,1.0f,0,
        0,0,0,1.0f
    };
    
    GLuint rotate = glGetUniformLocation(self.myProgram, "rotateMatrix");
    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRoatation[0]);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
}


//5.设置FrameBuffer
-(void)setupColorFrameBuffer{
    glGenBuffers(1, &_myColorFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
    //后续进行present
}


//4.设置renderBuffer
-(void)setupColorRenderBuffer{
    glGenBuffers(1, &_myColorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myLayer];
}

//3.删除render与Frame 的缓冲区
-(void)clearFrameAndRenderBuffer{
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
    glDeleteBuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
}


//2.创建上下文
-(void)creatContext{
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context) {
        NSLog(@"creat Context Failed!!!!");
        return;
    }
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"setCurrent Context Failed!!");
        return;
    }
    self.myContext = context;
    
}


//1.设置图层
-(void)setupLayer{
    self.myLayer = (CAEAGLLayer *)self.layer;
    
    [self setContentScaleFactor:[[UIScreen mainScreen]scale]];
    
    self.myLayer.opaque = YES;
    
    self.myLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:false],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
}



#pragma mark - tools for build shader

-(void) setupTexture:(NSString *)fileName{
    //先读取图片
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (spriteImage == nil) {
        NSLog(@"load CGImage failed : Name %@",fileName);
        //正常情况下退出程序
        exit(0);
    }
    //预先准备好图片相关信息
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    //放context内容的目标地址
    GLubyte *spriteByte = calloc(width * height * 4, sizeof(GLubyte));
    //加载一个context
    CGContextRef spriteContext = CGBitmapContextCreate(spriteByte, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    CGRect rect = CGRectMake(0, 0, width, height);
    //开始将图片内容画到context上
    CGContextDrawImage(spriteContext, rect, spriteImage);
    //此时context已经设置好内容了，并且保存到之前申请的spriteByte中了，所以释放
    CGContextRelease(spriteContext);
    
    
    //进行纹理相关操作
    glBindTexture(GL_TEXTURE_2D, 0);
    //设置过滤属性
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //先转个类型，载入纹理了
    float fw = width,fh = height;
    //前面的工作就是为了拿到最后这个数据，spriteByte
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteByte);
    glBindTexture(GL_TEXTURE_2D, 0);
    //把纹理拿到了以后，用完了前面的数据就把内存释放掉
    free(spriteByte);
    
}

//加载着色器
-(GLuint)loadShader:(NSString *)vertPath AndFragment:(NSString *)fragmentPath{
    GLuint verShader,fragShader;
    GLuint program = glCreateProgram();
    
    [self compileShader:&verShader type:GL_VERTEX_SHADER filePath:vertPath];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER filePath:fragmentPath];
    
    //创建程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //释放buffer
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}
//编译shader

-(void)compileShader:(GLuint *)shader type:(GLenum)type filePath:(NSString *)filePath{
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    const GLchar *source = (GLchar *)[content UTF8String];
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
}



//这个方法可以指定返回的calayer图层类型
+(Class)layerClass{
    return [CAEAGLLayer class];
}


@end
