#ifndef distance_functions_h
#define distance_functions_h

#include "foundation.cginc"

float kaleidoscopic_IFS(float3 z)
{
    int FRACT_ITER      = 20;
    float FRACT_SCALE   = 1.8;
    float FRACT_OFFSET  = 1.0;

    float c = 2.0;
    z.y = modc(z.y, c)-c/2.0;
    z = rotateZ(z, PI/2.0);
    float r;
    int n1 = 0;
    for (int n = 0; n < FRACT_ITER; n++) {
        float rotate = PI*0.5;
        z = rotateX(z, rotate);
        z = rotateY(z, rotate);
        z = rotateZ(z, rotate);

        z.xy = abs(z.xy);
        if (z.x+z.y<0.0) z.xy = -z.yx; // fold 1
        if (z.x+z.z<0.0) z.xz = -z.zx; // fold 2
        if (z.y+z.z<0.0) z.zy = -z.yz; // fold 3
        z = z*FRACT_SCALE - FRACT_OFFSET*(FRACT_SCALE-1.0);
    }
    return (length(z) ) * pow(FRACT_SCALE, -float(FRACT_ITER));
}


float tglad_formula(float3 z0)
{
    z0 = modc(z0, 2.0);

    float mr=0.25, mxr=1.0;
    float4 scale=float4(-3.12,-3.12,-3.12,3.12), p0=float4(0.0,1.59,-1.0,0.0);
    float4 z = float4(z0,1.0);
    for (int n = 0; n < 3; n++) {
        z.xyz=clamp(z.xyz, -0.94, 0.94)*2.0-z.xyz;
        z*=scale/clamp(dot(z.xyz,z.xyz),mr,mxr);
        z+=p0;
    }
    float dS=(length(max(abs(z.xyz)-float3(1.2,49.0,1.4),0.0))-0.06)/z.w;
    return dS;
}

float tglad_formula2(float3 z0, float s)
{
    z0 = modc(z0, 2 * s);

    float mr=0.5, mxr=1.0;
    float4 scale=float4(-3.12,-3.12,-3.12,3.12), p0=float4(0.0,1.59,-1.0,0.0);
    float4 z = float4(z0,1.0);
    for (int n = 0; n < 5; n++) {
        z.xyz=clamp(z.xyz, -0.94, 0.94)*2.0-z.xyz;
        z*=scale/clamp(dot(z.xyz,z.xyz),mr,mxr);
        z+=p0;
    }
    float dS=(length(max(abs(z.xyz)-float3(1.2,49.0,1.4),0.0))-0.06)/z.w;
    return dS;
}

float3 boxFold(float3 v)
{
	if (v.x > 1)
		v.x = 2 - v.x;
	else if (v.x < -1)
		v.x = -2 - v.x;

	if (v.z > 1)
		v.z = 2 - v.z;
	else if (v.z < -1)
		v.z = -2 - v.z;

	if (v.y > .5)
		v.y = 1 - v.y;
	else if (v.y < -.5)
		v.y = -1 - v.y;

	return v;
}

void boxFold2(inout float3 z, inout float dz) {
	float foldingLimit = 1;
	z = clamp(z, -foldingLimit, foldingLimit) * 2.0 - z;
}

float4 ballFold(float r, float4 v)
{
	float m = sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
	if (m < r)
		m = m / (r*r);
	else if (m < 1)
		m = 1 / (m*m);
	return v * m;
}

void sphereFold(inout float3 z, inout float dz) {
	float r2 = dot(z, z);
	float minRadius2 = 0.4;
	float fixedRadius2 = .8;

	if (r2 < minRadius2) {
		// linear inner scaling
		float temp = (fixedRadius2 / minRadius2);
		z *= temp;
		dz *= temp;
	}
	else if (r2 < fixedRadius2) {
		// this is the actual sphere inversion
		float temp = (fixedRadius2 / r2);
		z *= temp;
		dz *= temp;
	}
}

float tglad_formula3(float3 z, float s)
{
	float3 offset = z ;
	float Scale = s;
	float dr = 1.0;
	float Iterations = 10;
	
	for (int n = 0; n < Iterations; n++) {
		//z += .123;
		boxFold2(z, dr);       // Reflect
		sphereFold(z, dr);    // Sphere Inversion
		z = Scale*z + offset;  // Scale & Translate
		dr = dr*abs(Scale) + 1.0;
	}
	float r = length(z);
	//return dot(z,z) / length(z*dr);
	//return .5 * r * log(r)/abs(dr);
	return r / abs(dr);
}

float tglad_formula4(float3 z, float s)
{
	float3 offset = z;
	float Scale = s;
	float dr = 1.0;
	float Iterations = 8;

	for (int n = 0; n < Iterations; n++) {
		
		z = boxFold(z);

		sphereFold(z, dr);    // Sphere Inversion
		z = Scale*z + offset;  // Scale & Translate
		dr = dr*abs(Scale) + 1.0;
	}
	float r = length(z);
	//return dot(z,z) / length(z*dr);
	//return .5 * r * log(r)/abs(dr);
	return r / abs(dr);
}

float mandel1(float3 pos, float s)
{
	
	int ColorIterations = 3;
	int Iterations = 8;
	float4 p = float4(pos, 1), p0 = p;  // p.w is the distance estimate
	p0 = float4(1., -1., 1., 1.); // Julia mode for dummies ^_________^

	for (int i = 0; i<Iterations; i++) {
		//p.xyz *= rot;
		float nx = abs(p.x);
		float ny = abs(p.y);
		float nz = abs(p.z);
		float fo = .5;
		float g = .9;
		float fx = -2.*fo + nx;
		float fy = -2.*fo + ny;
		float fz = -2.*fo + nz;
		float xf = (fo - abs(-fo + nx));
		float yf = (fo - abs(-fo + ny));
		float zf = (fo - abs(-fo + nz));
		float gx = g + nx;
		float gy = g + ny;
		float gz = g + nz;

		if (fx > 0 && fx>ny&& fx>nz) {
			if (fx>gy&& fx>gz) {
				// square edge:
				xf += g;
				// orthogonal axis must stay ortho:
				yf = (fo - abs(g - fo + ny));
				zf = (fo - abs(g - fo + nz));
			}
			else {
				// top:
				xf = -max(ny, nz);
				// orthogonal axis must stay ortho:
				yf = (fo - abs(-3.*fo + max(nx, nz)));
				zf = (fo - abs(-3.*fo + max(ny, nx)));
			}
		}
		if (fy > 0 && fy>nx&& fy>nz) {
			if (fy>gx&& fy>gz) {
				// square edge:
				yf += g;
				// orthogonal axis must stay ortho:
				xf = (fo - abs(g - fo + nx));
				zf = (fo - abs(g - fo + nz));
			}
			else {
				// top:
				yf = -max(nx, nz);
				// orthogonal axis must stay ortho: 
				xf = (fo - abs(-3.*fo + max(ny, nz)));
				zf = (fo - abs(-3.*fo + max(ny, nx)));
			}
		}
		if (fz > 0 && fz>nx&& fz>ny) {
			if (fz>gx&& fz>gy) {
				// square edge:
				zf += g;
				// orthogonal axis must stay ortho:
				xf = (fo - abs(g - fo + nx));
				zf = (fo - abs(g - fo + nz));
			}
			else {
				// top:
				zf = -max(ny, nx);
				// orthogonal axis must stay ortho: 
				xf = (fo - abs(-3.*fo + max(ny, nz)));
				yf = (fo - abs(-3.*fo + max(nx, nz)));
			}
		}
		p.x = xf; p.y = yf; p.z = zf;
		float r2 = dot(p.xyz, p.xyz);
		//if (i<ColorIterations) orbitTrap = min(orbitTrap, abs(vec4(p.xyz, r2)));
		p *= clamp(max(.25 / r2, .25), 0.0, 1.0);  // dp3,div,max.sat,mul
		p = p*s + p0;
		if (r2>1000.0) break;

	}
	return ((length(p.xyz) - abs(s-1)) / p.w - pow(abs(s), float(1-Iterations)));
}

// distance function from Hartverdrahtet
// ( http://www.pouet.net/prod.php?which=59086 )
float hartverdrahtet(float3 f)
{
    float3 cs=float3(.808,.808,1.167);
    float fs=1.;
    float3 fc=0;
    float fu=10.;
    float fd=.763;
    
    // scene selection
    {
        float time = _Time.y;
        int i = int(modc(time/2.0, 9.0));
        if(i==0) cs.y=.58;
        if(i==1) cs.xy=.5;
        if(i==2) cs.xy=.5;
        if(i==3) fu=1.01,cs.x=.9;
        if(i==4) fu=1.01,cs.x=.9;
        if(i==6) cs=float3(.5,.5,1.04);
        if(i==5) fu=.9;
        if(i==7) fd=.7,fs=1.34,cs.xy=.5;
        if(i==8) fc.z=-.38;
    }
    
    //cs += sin(time)*0.2;

    float v=1.;
    for(int i=0; i<12; i++){
        f=2.*clamp(f,-cs,cs)-f;
        float c=max(fs/dot(f,f),1.);
        f*=c;
        v*=c;
        f+=fc;
    }
    float z=length(f.xy)-fu;
    return fd*max(z,abs(length(f.xy)*f.z)/sqrt(dot(f,f)))/abs(v);
}


// distance function from Hartverdrahtet
// ( http://www.pouet.net/prod.php?which=59086 )
float hartverdrahtet2(float3 f, float i)
{
    float3 cs=float3(.808,.808,1.167);
    float fs=1.;
    float3 fc=0;
    float fu=10.;
    float fd=.763;
    
    // scene selection
	if(i < 0)
    {
        float time = _Time.y;
        //int i = int(modc(time/2.0, 9.0));
        if(i==0) cs.y=.58;
        else if(i>=8) fc.z=-.38;
        else if(i>=7) fd=.7,fs=1.34,cs.xy=i/5;
        else if(i>=5) fu=.9;
        else if(i>=6) cs=float3(.5,.5,1.04);
        else if(i>=4) fu=1.01,cs.x=i/10;
        else if(i>=3) fu=1.01,cs.x=i/10;
        else if(i>=2) cs.xy=.5;
        else if(i>=1) cs.xy=.5;
    }
    fd=.5 + i/20,fs=1 + i / 10,cs.xy=i/5;
    //cs += sin(time)*0.2;

    float v=1.;
    for(int i=0; i<12; i++){
        f=2.*clamp(f,-cs,cs)-f;
        float c=max(fs/dot(f,f),1.);
        f*=c;
        v*=c;
        f+=fc;
    }
    float z=length(f.xy)-fu;
    return fd*max(z,abs(length(f.xy)*f.z)/sqrt(dot(f,f)))/abs(v);
}

float MandelBulbtest(float3 pos) {

	int Iterations = 20;
	float3 z = pos;
	float dr = 1.0;
	float r = 0.0;
	float Power = 8;
	float Bailout = 1000;

	for (int i = 0; i < Iterations; i++) {
		r = length(z);
		if (r>Bailout) break;

		// convert to polar coordinates
		float theta = acos(z.z / r);
		float phi = atan(z.yx);
		dr = pow(r, Power - 1.0)*Power*dr + 1.0;

		// scale and rotate the point
		float zr = pow(r, Power);
		theta = theta*Power;
		phi = phi*Power;

		// convert back to cartesian coordinates
		z = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
		z += pos;
	}
	return 0.5*log(r)*r / dr;
}

float pseudo_kleinian(float3 p)
{
    float3 CSize = float3(0.92436,0.90756,0.92436);
    float Size = 1.0;
    float3 C = float3(0.0,0.0,0.0);
    float DEfactor=1.;
    float3 Offset = float3(0.0,0.0,0.0);
    float3 ap=p+1.;
    for(int i=0;i<10 ;i++){
        ap=p;
        p=2.*clamp(p, -CSize, CSize)-p;
        float r2 = dot(p,p);
        float k = max(Size/r2,1.);
        p *= k;
        DEfactor *= k + 0.05;
        p += C;
    }
    float r = abs(0.5*abs(p.z-Offset.z)/DEfactor);
    return r;
}

float pseudo_knightyan(float3 p)
{
    float3 CSize = float3(0.63248,0.78632,0.875);
    float DEfactor=1.;
    for(int i=0;i<6;i++){
        p = 2.*clamp(p, -CSize, CSize)-p;
        float k = max(0.70968/dot(p,p),1.);
        p *= k;
        DEfactor *= k + 0.05;
    }
    float rxy=length(p.xy);
    return max(rxy-0.92784, abs(rxy*p.z) / length(p))/DEfactor;
}

#endif // distance_functions_h
