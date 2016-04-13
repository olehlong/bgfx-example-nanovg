import std.conv : text, to;
import std.stdio;
import std.math;
import core.time;
import std.string : toStringz;

import blendish;

import bx = bx.bx;
import bgfx = bgfx.bgfx;
import bgfx.defines : BGFX_DEBUG_TEXT, BGFX_RESET_VSYNC, 
                        BGFX_PCI_ID_NONE, BGFX_CLEAR_COLOR, 
                        BGFX_CLEAR_DEPTH;
import bgfx.platform : PlatformData, setPlatformData;

import bgfx_extras.nanovg;

import derelict.sdl2.sdl;

enum ICON_SEARCH = 0x1F50D;
enum ICON_CIRCLED_CROSS = 0x2716;
enum ICON_CHEVRON_RIGHT = 0xE75E;
enum ICON_CHECK = 0x2713;
enum ICON_LOGIN = 0xE740;
enum ICON_TRASH = 0xE729;

// Returns 1 if col.rgba is 0.0f,0.0f,0.0f,0.0f, 0 otherwise
int isBlack(NVGcolor col) {
	if(col.r == 0.0f && col.g == 0.0f && col.b == 0.0f && col.a == 0.0f) {
		return 1;
	}
	return 0;
}

char* cpToUTF8(int cp, char* str) {
	int n = 0;
	if (cp < 0x80) n = 1;
	else if (cp < 0x800) n = 2;
	else if (cp < 0x10000) n = 3;
	else if (cp < 0x200000) n = 4;
	else if (cp < 0x4000000) n = 5;
	else if (cp <= 0x7fffffff) n = 6;
	str[n] = '\0';
	switch (n) {
		case 6: str[5] = 0x80 | (cp & 0x3f); cp = cp >> 6; cp |= 0x4000000; break;
		case 5: str[4] = 0x80 | (cp & 0x3f); cp = cp >> 6; cp |= 0x200000; break;
		case 4: str[3] = 0x80 | (cp & 0x3f); cp = cp >> 6; cp |= 0x10000; break;
		case 3: str[2] = 0x80 | (cp & 0x3f); cp = cp >> 6; cp |= 0x800; break;
		case 2: str[1] = 0x80 | (cp & 0x3f); cp = cp >> 6; cp |= 0xc0; break;
		case 1: str[0] = cast(char)cp; break;
        default: break;
	}
	return str;
}

void drawWindow(NVGcontext* vg, const(char)* title, float x, float y, float w, float h) {
	float cornerRadius = 3.0f;
	NVGpaint shadowPaint;
	NVGpaint headerPaint;

	nvgSave(vg);
	//	nvgClearState(vg);

	// Window
	nvgBeginPath(vg);
	nvgRoundedRect(vg, x,y, w,h, cornerRadius);
	nvgFillColor(vg, nvgRGBA(28,30,34,192) );
	//	nvgFillColor(vg, nvgRGBA(0,0,0,128) );
	nvgFill(vg);

	// Drop shadow
	shadowPaint = nvgBoxGradient(vg, x,y+2, w,h, cornerRadius*2, 10, nvgRGBA(0,0,0,128), nvgRGBA(0,0,0,0));
	nvgBeginPath(vg);
	nvgRect(vg, x-10,y-10, w+20,h+30);
	nvgRoundedRect(vg, x,y, w,h, cornerRadius);
	nvgPathWinding(vg, NVGsolidity.NVG_HOLE);
	nvgFillPaint(vg, shadowPaint);
	nvgFill(vg);

	// Header
	headerPaint = nvgLinearGradient(vg, x,y,x,y+15, nvgRGBA(255,255,255,8), nvgRGBA(0,0,0,16));
	nvgBeginPath(vg);
	nvgRoundedRect(vg, x+1,y+1, w-2,30, cornerRadius-1);
	nvgFillPaint(vg, headerPaint);
	nvgFill(vg);
	nvgBeginPath(vg);
	nvgMoveTo(vg, x+0.5f, y+0.5f+30);
	nvgLineTo(vg, x+0.5f+w-1, y+0.5f+30);
	nvgStrokeColor(vg, nvgRGBA(0,0,0,32) );
	nvgStroke(vg);

	nvgFontSize(vg, 18.0f);
	nvgFontFace(vg, "sans-bold");
	nvgTextAlign(vg, NVGalign.NVG_ALIGN_CENTER|NVGalign.NVG_ALIGN_MIDDLE);

	nvgFontBlur(vg,2);
	nvgFillColor(vg, nvgRGBA(0,0,0,128) );
	nvgText(vg, x+w/2,y+16+1, title, null);

	nvgFontBlur(vg,0);
	nvgFillColor(vg, nvgRGBA(220,220,220,160) );
	nvgText(vg, x+w/2,y+16, title, null);

	nvgRestore(vg);
}

void drawSearchBox(NVGcontext* vg, const(char)* text, float x, float y, float w, float h) {
	NVGpaint bg;
	char[8] icon;
	float cornerRadius = h/2-1;

	// Edit
	bg = nvgBoxGradient(vg, x,y+1.5f, w,h, h/2,5, nvgRGBA(0,0,0,16), nvgRGBA(0,0,0,92) );
	nvgBeginPath(vg);
	nvgRoundedRect(vg, x,y, w,h, cornerRadius);
	nvgFillPaint(vg, bg);
	nvgFill(vg);

	/*	nvgBeginPath(vg);
		nvgRoundedRect(vg, x+0.5f,y+0.5f, w-1,h-1, cornerRadius-0.5f);
		nvgStrokeColor(vg, nvgRGBA(0,0,0,48) );
		nvgStroke(vg);*/

	nvgFontSize(vg, h*1.3f);
	nvgFontFace(vg, "icons");
	nvgFillColor(vg, nvgRGBA(255,255,255,64) );
	nvgTextAlign(vg, NVGalign.NVG_ALIGN_CENTER|NVGalign.NVG_ALIGN_MIDDLE);
	nvgText(vg, x+h*0.55f, y+h*0.55f, cpToUTF8(ICON_SEARCH, icon.ptr), null);

	nvgFontSize(vg, 20.0f);
	nvgFontFace(vg, "sans");
	nvgFillColor(vg, nvgRGBA(255,255,255,32) );

	nvgTextAlign(vg, NVGalign.NVG_ALIGN_LEFT|NVGalign.NVG_ALIGN_MIDDLE);
	nvgText(vg, x+h*1.05f,y+h*0.5f,text, null);

	nvgFontSize(vg, h*1.3f);
	nvgFontFace(vg, "icons");
	nvgFillColor(vg, nvgRGBA(255,255,255,32) );
	nvgTextAlign(vg, NVGalign.NVG_ALIGN_CENTER|NVGalign.NVG_ALIGN_MIDDLE);
	nvgText(vg, x+w-h*0.55f, y+h*0.55f, cpToUTF8(ICON_CIRCLED_CROSS, icon.ptr), null);
}

void drawDropDown(NVGcontext* vg, const char* text, float x, float y, float w, float h) {
	NVGpaint bg;
	char[8] icon;
	float cornerRadius = 4.0f;

	bg = nvgLinearGradient(vg, x,y,x,y+h, nvgRGBA(255,255,255,16), nvgRGBA(0,0,0,16) );
	nvgBeginPath(vg);
	nvgRoundedRect(vg, x+1,y+1, w-2,h-2, cornerRadius-1);
	nvgFillPaint(vg, bg);
	nvgFill(vg);

	nvgBeginPath(vg);
	nvgRoundedRect(vg, x+0.5f,y+0.5f, w-1,h-1, cornerRadius-0.5f);
	nvgStrokeColor(vg, nvgRGBA(0,0,0,48) );
	nvgStroke(vg);

	nvgFontSize(vg, 20.0f);
	nvgFontFace(vg, "sans");
	nvgFillColor(vg, nvgRGBA(255,255,255,160) );
	nvgTextAlign(vg, NVGalign.NVG_ALIGN_LEFT|NVGalign.NVG_ALIGN_MIDDLE);
	nvgText(vg, x+h*0.3f,y+h*0.5f,text, null);

	nvgFontSize(vg, h*1.3f);
	nvgFontFace(vg, "icons");
	nvgFillColor(vg, nvgRGBA(255,255,255,64) );
	nvgTextAlign(vg, NVGalign.NVG_ALIGN_CENTER|NVGalign.NVG_ALIGN_MIDDLE);
	nvgText(vg, x+w-h*0.5f, y+h*0.5f, cpToUTF8(ICON_CHEVRON_RIGHT, icon.ptr), null);
}

void drawLabel(NVGcontext* vg, const(char)* text, float x, float y, float w, float h) {
	nvgFontSize(vg, 18.0f);
	nvgFontFace(vg, "sans");
	nvgFillColor(vg, nvgRGBA(255, 128, 0, 255));
	nvgTextAlign(vg, NVGalign.NVG_ALIGN_LEFT|NVGalign.NVG_ALIGN_MIDDLE);
	nvgText(vg, x, y+h*0.5f, text, null);
}

void drawEditBoxBase(NVGcontext* vg, float x, float y, float w, float h) {
	NVGpaint bg;
	// Edit
	bg = nvgBoxGradient(vg, x+1,y+1+1.5f, w-2,h-2, 3,4, nvgRGBA(255,255,255,32), nvgRGBA(32,32,32,32));
	nvgBeginPath(vg);
	nvgRoundedRect(vg, x+1,y+1, w-2,h-2, 4-1);
	nvgFillPaint(vg, bg);
	nvgFill(vg);

	nvgBeginPath(vg);
	nvgRoundedRect(vg, x+0.5f,y+0.5f, w-1,h-1, 4-0.5f);
	nvgStrokeColor(vg, nvgRGBA(0,0,0,48));
	nvgStroke(vg);
}

void drawEditBox(NVGcontext* vg, const(char)* text, float x, float y, float w, float h) {
	drawEditBoxBase(vg, x,y, w,h);

	nvgFontSize(vg, 20.0f);
	nvgFontFace(vg, "sans");
	nvgFillColor(vg, nvgRGBA(255,255,255,64));
	nvgTextAlign(vg, NVGalign.NVG_ALIGN_LEFT|NVGalign.NVG_ALIGN_MIDDLE);
	nvgText(vg, x+h*0.3f,y+h*0.5f,text, null);
}

void drawEditBoxNum(NVGcontext* vg, const(char)* text, const(char)* units, float x, float y, float w, float h) {
	float uw;

	drawEditBoxBase(vg, x,y, w,h);

	uw = nvgTextBounds(vg, 0,0, units, null, null);

	nvgFontSize(vg, 18.0f);
	nvgFontFace(vg, "sans");
	nvgFillColor(vg, nvgRGBA(255,255,255,64));
	nvgTextAlign(vg, NVGalign.NVG_ALIGN_RIGHT|NVGalign.NVG_ALIGN_MIDDLE);
	nvgText(vg, x+w-h*0.3f,y+h*0.5f,units, null);

	nvgFontSize(vg, 20.0f);
	nvgFontFace(vg, "sans");
	nvgFillColor(vg, nvgRGBA(255,255,255,128));
	nvgTextAlign(vg, NVGalign.NVG_ALIGN_RIGHT|NVGalign.NVG_ALIGN_MIDDLE);
	nvgText(vg, x+w-uw-h*0.5f,y+h*0.5f,text, null);
}

void drawCheckBox(NVGcontext* vg, const(char)* text, float x, float y, float w, float h) {
	NVGpaint bg;
	char[8] icon;

	nvgFontSize(vg, 18.0f);
	nvgFontFace(vg, "sans");
	nvgFillColor(vg, nvgRGBA(255,255,255,160) );

	nvgTextAlign(vg, NVGalign.NVG_ALIGN_LEFT|NVGalign.NVG_ALIGN_MIDDLE);
	nvgText(vg, x+28,y+h*0.5f,text, null);

	bg = nvgBoxGradient(vg, x+1,y+cast(int)(h*0.5f)-9+1, 18,18, 3,3, nvgRGBA(0,0,0,32), nvgRGBA(0,0,0,92));
	nvgBeginPath(vg);
	nvgRoundedRect(vg, x+1,y+cast(int)(h*0.5f)-9, 18,18, 3);
	nvgFillPaint(vg, bg);
	nvgFill(vg);

	nvgFontSize(vg, 40);
	nvgFontFace(vg, "icons");
	nvgFillColor(vg, nvgRGBA(255,255,255,128) );
	nvgTextAlign(vg, NVGalign.NVG_ALIGN_CENTER|NVGalign.NVG_ALIGN_MIDDLE);
	nvgText(vg, x+9+2, y+h*0.5f, cpToUTF8(ICON_CHECK, icon.ptr), null);
}

void drawButton(NVGcontext* vg, int preicon, const(char)* text, float x, float y, float w, float h, NVGcolor col) {
	NVGpaint bg;
	char[8] icon;
	float cornerRadius = 4.0f;
	float tw = 0, iw = 0;

	bg = nvgLinearGradient(vg, x,y,x,y+h, nvgRGBA(255,255,255,isBlack(col)?16:32), nvgRGBA(0,0,0,isBlack(col)?16:32));
	nvgBeginPath(vg);
	nvgRoundedRect(vg, x+1,y+1, w-2,h-2, cornerRadius-1);
	if (!isBlack(col)) {
		nvgFillColor(vg, col);
		nvgFill(vg);
	}
	nvgFillPaint(vg, bg);
	nvgFill(vg);

	nvgBeginPath(vg);
	nvgRoundedRect(vg, x+0.5f,y+0.5f, w-1,h-1, cornerRadius-0.5f);
	nvgStrokeColor(vg, nvgRGBA(0,0,0,48) );
	nvgStroke(vg);

	nvgFontSize(vg, 20.0f);
	nvgFontFace(vg, "sans-bold");
	tw = nvgTextBounds(vg, 0,0, text, null, null);
	if (preicon != 0) {
		nvgFontSize(vg, h*1.3f);
		nvgFontFace(vg, "icons");
		iw = nvgTextBounds(vg, 0,0, cpToUTF8(preicon, icon.ptr), null, null);
		iw += h*0.15f;
	}

	if (preicon != 0) {
		nvgFontSize(vg, h*1.3f);
		nvgFontFace(vg, "icons");
		nvgFillColor(vg, nvgRGBA(255,255,255,96) );
		nvgTextAlign(vg, NVGalign.NVG_ALIGN_LEFT|NVGalign.NVG_ALIGN_MIDDLE);
		nvgText(vg, x+w*0.5f-tw*0.5f-iw*0.75f, y+h*0.5f, cpToUTF8(preicon, icon.ptr), null);
	}

	nvgFontSize(vg, 20.0f);
	nvgFontFace(vg, "sans-bold");
	nvgTextAlign(vg, NVGalign.NVG_ALIGN_LEFT|NVGalign.NVG_ALIGN_MIDDLE);
	nvgFillColor(vg, nvgRGBA(0,0,0,160) );
	nvgText(vg, x+w*0.5f-tw*0.5f+iw*0.25f,y+h*0.5f-1,text, null);
	nvgFillColor(vg, nvgRGBA(255,255,255,160) );
	nvgText(vg, x+w*0.5f-tw*0.5f+iw*0.25f,y+h*0.5f,text, null);
}

void drawSlider(NVGcontext* vg, float pos, float x, float y, float w, float h) {
	NVGpaint bg, knob;
	float cy = y+cast(int)(h*0.5f);
	float kr = cast(float)(cast(int)(h*0.25f));

	nvgSave(vg);
	//	nvgClearState(vg);

	// Slot
	bg = nvgBoxGradient(vg, x,cy-2+1, w,4, 2,2, nvgRGBA(0,0,0,32), nvgRGBA(0,0,0,128));
	nvgBeginPath(vg);
	nvgRoundedRect(vg, x,cy-2, w,4, 2);
	nvgFillPaint(vg, bg);
	nvgFill(vg);

	// Knob Shadow
	bg = nvgRadialGradient(vg, x+cast(int)(pos*w),cy+1, kr-3,kr+3, nvgRGBA(0,0,0,64), nvgRGBA(0,0,0,0));
	nvgBeginPath(vg);
	nvgRect(vg, x+cast(int)(pos*w)-kr-5,cy-kr-5,kr*2+5+5,kr*2+5+5+3);
	nvgCircle(vg, x+cast(int)(pos*w),cy, kr);
	nvgPathWinding(vg, NVGsolidity.NVG_HOLE);
	nvgFillPaint(vg, bg);
	nvgFill(vg);

	// Knob
	knob = nvgLinearGradient(vg, x,cy-kr,x,cy+kr, nvgRGBA(255,255,255,16), nvgRGBA(0,0,0,16));
	nvgBeginPath(vg);
	nvgCircle(vg, x+cast(int)(pos*w),cy, kr-1);
	nvgFillColor(vg, nvgRGBA(40,43,48,255));
	nvgFill(vg);
	nvgFillPaint(vg, knob);
	nvgFill(vg);

	nvgBeginPath(vg);
	nvgCircle(vg, x+cast(int)(pos*w),cy, kr-0.5f);
	nvgStrokeColor(vg, nvgRGBA(0,0,0,92));
	nvgStroke(vg);

	nvgRestore(vg);
}

void drawEyes(NVGcontext* vg, float x, float y, float w, float h, float mx, float my, float t) {
	NVGpaint gloss, bg;
	float ex = w *0.23f;
	float ey = h * 0.5f;
	float lx = x + ex;
	float ly = y + ey;
	float rx = x + w - ex;
	float ry = y + ey;
	float dx,dy,d;
	float br = (ex < ey ? ex : ey) * 0.5f;
	float blink = 1 - pow(sin(t*0.5f),200)*0.8f;

	bg = nvgLinearGradient(vg, x,y+h*0.5f,x+w*0.1f,y+h, nvgRGBA(0,0,0,32), nvgRGBA(0,0,0,16));
	nvgBeginPath(vg);
	nvgEllipse(vg, lx+3.0f,ly+16.0f, ex,ey);
	nvgEllipse(vg, rx+3.0f,ry+16.0f, ex,ey);
	nvgFillPaint(vg, bg);
	nvgFill(vg);

	bg = nvgLinearGradient(vg, x,y+h*0.25f,x+w*0.1f,y+h, nvgRGBA(220,220,220,255), nvgRGBA(128,128,128,255));
	nvgBeginPath(vg);
	nvgEllipse(vg, lx,ly, ex,ey);
	nvgEllipse(vg, rx,ry, ex,ey);
	nvgFillPaint(vg, bg);
	nvgFill(vg);

	dx = (mx - rx) / (ex * 10);
	dy = (my - ry) / (ey * 10);
	d = sqrt(dx*dx+dy*dy);
	if (d > 1.0f) {
		dx /= d; dy /= d;
	}
	dx *= ex*0.4f;
	dy *= ey*0.5f;
	nvgBeginPath(vg);
	nvgEllipse(vg, lx+dx,ly+dy+ey*0.25f*(1-blink), br,br*blink);
	nvgFillColor(vg, nvgRGBA(32,32,32,255));
	nvgFill(vg);

	dx = (mx - rx) / (ex * 10);
	dy = (my - ry) / (ey * 10);
	d = sqrt(dx*dx+dy*dy);
	if (d > 1.0f) {
		dx /= d; dy /= d;
	}
	dx *= ex*0.4f;
	dy *= ey*0.5f;
	nvgBeginPath(vg);
	nvgEllipse(vg, rx+dx,ry+dy+ey*0.25f*(1-blink), br,br*blink);
	nvgFillColor(vg, nvgRGBA(32,32,32,255));
	nvgFill(vg);

	gloss = nvgRadialGradient(vg, lx-ex*0.25f,ly-ey*0.5f, ex*0.1f,ex*0.75f, nvgRGBA(255,255,255,128), nvgRGBA(255,255,255,0));
	nvgBeginPath(vg);
	nvgEllipse(vg, lx,ly, ex,ey);
	nvgFillPaint(vg, gloss);
	nvgFill(vg);

	gloss = nvgRadialGradient(vg, rx-ex*0.25f,ry-ey*0.5f, ex*0.1f,ex*0.75f, nvgRGBA(255,255,255,128), nvgRGBA(255,255,255,0));
	nvgBeginPath(vg);
	nvgEllipse(vg, rx,ry, ex,ey);
	nvgFillPaint(vg, gloss);
	nvgFill(vg);
}

void drawGraph(NVGcontext* vg, float x, float y, float w, float h, float t) {
	NVGpaint bg;
	float[6] samples;
	float[6] sx, sy;
	float dx = w/5.0f;
	int i;

	samples[0] = (1+sin(t*1.2345f+cos(t*0.33457f)*0.44f) )*0.5f;
	samples[1] = (1+sin(t*0.68363f+cos(t*1.3f)*1.55f) )*0.5f;
	samples[2] = (1+sin(t*1.1642f+cos(t*0.33457f)*1.24f) )*0.5f;
	samples[3] = (1+sin(t*0.56345f+cos(t*1.63f)*0.14f) )*0.5f;
	samples[4] = (1+sin(t*1.6245f+cos(t*0.254f)*0.3f) )*0.5f;
	samples[5] = (1+sin(t*0.345f+cos(t*0.03f)*0.6f) )*0.5f;

	for (i = 0; i < 6; i++) {
		sx[i] = x+i*dx;
		sy[i] = y+h*samples[i]*0.8f;
	}

	// Graph background
	bg = nvgLinearGradient(vg, x,y,x,y+h, nvgRGBA(0,160,192,0), nvgRGBA(0,160,192,64) );
	nvgBeginPath(vg);
	nvgMoveTo(vg, sx[0], sy[0]);
	for (i = 1; i < 6; i++)
		nvgBezierTo(vg, sx[i-1]+dx*0.5f,sy[i-1], sx[i]-dx*0.5f,sy[i], sx[i],sy[i]);
	nvgLineTo(vg, x+w, y+h);
	nvgLineTo(vg, x, y+h);
	nvgFillPaint(vg, bg);
	nvgFill(vg);

	// Graph line
	nvgBeginPath(vg);
	nvgMoveTo(vg, sx[0], sy[0]+2);
	for (i = 1; i < 6; i++)
		nvgBezierTo(vg, sx[i-1]+dx*0.5f,sy[i-1]+2, sx[i]-dx*0.5f,sy[i]+2, sx[i],sy[i]+2);
	nvgStrokeColor(vg, nvgRGBA(0,0,0,32) );
	nvgStrokeWidth(vg, 3.0f);
	nvgStroke(vg);

	nvgBeginPath(vg);
	nvgMoveTo(vg, sx[0], sy[0]);
	for (i = 1; i < 6; i++)
		nvgBezierTo(vg, sx[i-1]+dx*0.5f,sy[i-1], sx[i]-dx*0.5f,sy[i], sx[i],sy[i]);
	nvgStrokeColor(vg, nvgRGBA(0,160,192,255) );
	nvgStrokeWidth(vg, 3.0f);
	nvgStroke(vg);

	// Graph sample pos
	for (i = 0; i < 6; i++) {
		bg = nvgRadialGradient(vg, sx[i],sy[i]+2, 3.0f,8.0f, nvgRGBA(0,0,0,32), nvgRGBA(0,0,0,0) );
		nvgBeginPath(vg);
		nvgRect(vg, sx[i]-10, sy[i]-10+2, 20,20);
		nvgFillPaint(vg, bg);
		nvgFill(vg);
	}

	nvgBeginPath(vg);
	for (i = 0; i < 6; i++)
		nvgCircle(vg, sx[i], sy[i], 4.0f);
	nvgFillColor(vg, nvgRGBA(0,160,192,255) );
	nvgFill(vg);
	nvgBeginPath(vg);
	for (i = 0; i < 6; i++)
		nvgCircle(vg, sx[i], sy[i], 2.0f);
	nvgFillColor(vg, nvgRGBA(220,220,220,255) );
	nvgFill(vg);

	nvgStrokeWidth(vg, 1.0f);
}

void drawThumbnails(NVGcontext* vg, float x, float y, float w, float h, const(int)* images, int nimages, float t) {
	float cornerRadius = 3.0f;
	NVGpaint shadowPaint, imgPaint, fadePaint;
	float ix,iy,iw,ih;
	float thumb = 60.0f;
	float arry = 30.5f;
	int imgw, imgh;
	float stackh = (nimages/2) * (thumb+10) + 10;
	int i;
	float u = (1+cos(t*0.5f) )*0.5f;
	float scrollh;

	nvgSave(vg);
	//	nvgClearState(vg);

	// Drop shadow
	shadowPaint = nvgBoxGradient(vg, x,y+4, w,h, cornerRadius*2, 20, nvgRGBA(0,0,0,128), nvgRGBA(0,0,0,0) );
	nvgBeginPath(vg);
	nvgRect(vg, x-10,y-10, w+20,h+30);
	nvgRoundedRect(vg, x,y, w,h, cornerRadius);
	nvgPathWinding(vg, NVGsolidity.NVG_HOLE);
	nvgFillPaint(vg, shadowPaint);
	nvgFill(vg);

	// Window
	nvgBeginPath(vg);
	nvgRoundedRect(vg, x,y, w,h, cornerRadius);
	nvgMoveTo(vg, x-10,y+arry);
	nvgLineTo(vg, x+1,y+arry-11);
	nvgLineTo(vg, x+1,y+arry+11);
	nvgFillColor(vg, nvgRGBA(200,200,200,255) );
	nvgFill(vg);

	nvgSave(vg);
	nvgScissor(vg, x,y,w,h);
	nvgTranslate(vg, 0, -(stackh - h)*u);

	for (i = 0; i < nimages; i++) {
		float tx, ty;
		tx = x+10;
		ty = y+10;
		tx += (i%2) * (thumb+10);
		ty += (i/2) * (thumb+10);
		nvgImageSize(vg, images[i], &imgw, &imgh);
		if (imgw < imgh) {
			iw = thumb;
			ih = iw * cast(float)imgh/cast(float)imgw;
			ix = 0;
			iy = -(ih-thumb)*0.5f;
		} else {
			ih = thumb;
			iw = ih * cast(float)imgw/cast(float)imgh;
			ix = -(iw-thumb)*0.5f;
			iy = 0;
		}
		imgPaint = nvgImagePattern(vg, tx+ix, ty+iy, iw,ih, 0.0f/180.0f*NVG_PI, images[i], 0);
		nvgBeginPath(vg);
		nvgRoundedRect(vg, tx,ty, thumb,thumb, 5);
		nvgFillPaint(vg, imgPaint);
		nvgFill(vg);

		shadowPaint = nvgBoxGradient(vg, tx-1,ty, thumb+2,thumb+2, 5, 3, nvgRGBA(0,0,0,128), nvgRGBA(0,0,0,0) );
		nvgBeginPath(vg);
		nvgRect(vg, tx-5,ty-5, thumb+10,thumb+10);
		nvgRoundedRect(vg, tx,ty, thumb,thumb, 6);
		nvgPathWinding(vg, NVGsolidity.NVG_HOLE);
		nvgFillPaint(vg, shadowPaint);
		nvgFill(vg);

		nvgBeginPath(vg);
		nvgRoundedRect(vg, tx+0.5f,ty+0.5f, thumb-1,thumb-1, 4-0.5f);
		nvgStrokeWidth(vg,1.0f);
		nvgStrokeColor(vg, nvgRGBA(255,255,255,192) );
		nvgStroke(vg);
	}
	nvgRestore(vg);

	// Hide fades
	fadePaint = nvgLinearGradient(vg, x,y,x,y+6, nvgRGBA(200,200,200,255), nvgRGBA(200,200,200,0) );
	nvgBeginPath(vg);
	nvgRect(vg, x+4,y,w-8,6);
	nvgFillPaint(vg, fadePaint);
	nvgFill(vg);

	fadePaint = nvgLinearGradient(vg, x,y+h,x,y+h-6, nvgRGBA(200,200,200,255), nvgRGBA(200,200,200,0) );
	nvgBeginPath(vg);
	nvgRect(vg, x+4,y+h-6,w-8,6);
	nvgFillPaint(vg, fadePaint);
	nvgFill(vg);

	// Scroll bar
	shadowPaint = nvgBoxGradient(vg, x+w-12+1,y+4+1, 8,h-8, 3,4, nvgRGBA(0,0,0,32), nvgRGBA(0,0,0,92) );
	nvgBeginPath(vg);
	nvgRoundedRect(vg, x+w-12,y+4, 8,h-8, 3);
	nvgFillPaint(vg, shadowPaint);
	//	nvgFillColor(vg, nvgRGBA(255,0,0,128) );
	nvgFill(vg);

	scrollh = (h/stackh) * (h-8);
	shadowPaint = nvgBoxGradient(vg, x+w-12-1,y+4+(h-8-scrollh)*u-1, 8,scrollh, 3,4, nvgRGBA(220,220,220,255), nvgRGBA(128,128,128,255) );
	nvgBeginPath(vg);
	nvgRoundedRect(vg, x+w-12+1,y+4+1 + (h-8-scrollh)*u, 8-2,scrollh-2, 2);
	nvgFillPaint(vg, shadowPaint);
	//	nvgFillColor(vg, nvgRGBA(0,0,0,128) );
	nvgFill(vg);

	nvgRestore(vg);
}

void drawColorwheel(NVGcontext* vg, float x, float y, float w, float h, float t) {
	int i;
	float r0, r1, ax,ay, bx,by, cx,cy, aeps, r;
	float hue = sin(t * 0.12f);
	NVGpaint paint;

	nvgSave(vg);

	/*	nvgBeginPath(vg);
		nvgRect(vg, x,y,w,h);
		nvgFillColor(vg, nvgRGBA(255,0,0,128) );
		nvgFill(vg);*/

	cx = x + w*0.5f;
	cy = y + h*0.5f;
	r1 = (w < h ? w : h) * 0.5f - 5.0f;
	r0 = r1 - 20.0f;
	aeps = 0.5f / r1;	// half a pixel arc length in radians (2pi cancels out).

	for (i = 0; i < 6; i++)
	{
		float a0 = cast(float)i / 6.0f * NVG_PI * 2.0f - aeps;
		float a1 = cast(float)(i+1.0f) / 6.0f * NVG_PI * 2.0f + aeps;
		nvgBeginPath(vg);
		nvgArc(vg, cx,cy, r0, a0, a1, NVGwinding.NVG_CW);
		nvgArc(vg, cx,cy, r1, a1, a0, NVGwinding.NVG_CCW);
		nvgClosePath(vg);
		ax = cx + cos(a0) * (r0+r1)*0.5f;
		ay = cy + sin(a0) * (r0+r1)*0.5f;
		bx = cx + cos(a1) * (r0+r1)*0.5f;
		by = cy + sin(a1) * (r0+r1)*0.5f;
		paint = nvgLinearGradient(vg, ax,ay, bx,by, nvgHSLA(a0/(NVG_PI*2),1.0f,0.55f,255), nvgHSLA(a1/(NVG_PI*2),1.0f,0.55f,255));
		nvgFillPaint(vg, paint);
		nvgFill(vg);
	}

	nvgBeginPath(vg);
	nvgCircle(vg, cx,cy, r0-0.5f);
	nvgCircle(vg, cx,cy, r1+0.5f);
	nvgStrokeColor(vg, nvgRGBA(0,0,0,64) );
	nvgStrokeWidth(vg, 1.0f);
	nvgStroke(vg);

	// Selector
	nvgSave(vg);
	nvgTranslate(vg, cx,cy);
	nvgRotate(vg, hue*NVG_PI*2);

	// Marker on
	nvgStrokeWidth(vg, 2.0f);
	nvgBeginPath(vg);
	nvgRect(vg, r0-1,-3,r1-r0+2,6);
	nvgStrokeColor(vg, nvgRGBA(255,255,255,192));
	nvgStroke(vg);

	paint = nvgBoxGradient(vg, r0-3,-5,r1-r0+6,10, 2,4, nvgRGBA(0,0,0,128), nvgRGBA(0,0,0,0));
	nvgBeginPath(vg);
	nvgRect(vg, r0-2-10,-4-10,r1-r0+4+20,8+20);
	nvgRect(vg, r0-2,-4,r1-r0+4,8);
	nvgPathWinding(vg, NVGsolidity.NVG_HOLE);
	nvgFillPaint(vg, paint);
	nvgFill(vg);

	// Center triangle
	r = r0 - 6;
	ax = cos(120.0f/180.0f*NVG_PI) * r;
	ay = sin(120.0f/180.0f*NVG_PI) * r;
	bx = cos(-120.0f/180.0f*NVG_PI) * r;
	by = sin(-120.0f/180.0f*NVG_PI) * r;
	nvgBeginPath(vg);
	nvgMoveTo(vg, r,0);
	nvgLineTo(vg, ax,ay);
	nvgLineTo(vg, bx,by);
	nvgClosePath(vg);
	paint = nvgLinearGradient(vg, r,0, ax,ay, nvgHSLA(hue,1.0f,0.5f,255), nvgRGBA(255,255,255,255));
	nvgFillPaint(vg, paint);
	nvgFill(vg);
	paint = nvgLinearGradient(vg, (r+ax)*0.5f,(0+ay)*0.5f, bx,by, nvgRGBA(0,0,0,0), nvgRGBA(0,0,0,255));
	nvgFillPaint(vg, paint);
	nvgFill(vg);
	nvgStrokeColor(vg, nvgRGBA(0,0,0,64) );
	nvgStroke(vg);

	// Select circle on triangle
	ax = cos(120.0f/180.0f*NVG_PI) * r*0.3f;
	ay = sin(120.0f/180.0f*NVG_PI) * r*0.4f;
	nvgStrokeWidth(vg, 2.0f);
	nvgBeginPath(vg);
	nvgCircle(vg, ax,ay,5);
	nvgStrokeColor(vg, nvgRGBA(255,255,255,192) );
	nvgStroke(vg);

	paint = nvgRadialGradient(vg, ax,ay, 7,9, nvgRGBA(0,0,0,64), nvgRGBA(0,0,0,0));
	nvgBeginPath(vg);
	nvgRect(vg, ax-20,ay-20,40,40);
	nvgCircle(vg, ax,ay,7);
	nvgPathWinding(vg, NVGsolidity.NVG_HOLE);
	nvgFillPaint(vg, paint);
	nvgFill(vg);

	nvgRestore(vg);

	nvgRestore(vg);
}

void drawLines(NVGcontext* vg, float x, float y, float w, float h, float t) {
	int i, j;
	float pad = 5.0f, s = w/9.0f - pad*2;
	float[4*2] pts;
    float fx, fy;
	int[3] joins = [NVGlineCap.NVG_MITER, NVGlineCap.NVG_ROUND, NVGlineCap.NVG_BEVEL];
	int[3] caps = [NVGlineCap.NVG_BUTT, NVGlineCap.NVG_ROUND, NVGlineCap.NVG_SQUARE];

	nvgSave(vg);
	pts[0] = -s*0.25f + cos(t*0.3f) * s*0.5f;
	pts[1] = sin(t*0.3f) * s*0.5f;
	pts[2] = -s*0.25f;
	pts[3] = 0;
	pts[4] = s*0.25f;
	pts[5] = 0;
	pts[6] = s*0.25f + cos(-t*0.3f) * s*0.5f;
	pts[7] = sin(-t*0.3f) * s*0.5f;

	for (i = 0; i < 3; i++)	{
		for (j = 0; j < 3; j++)	{
			fx = x + s*0.5f + (i*3+j)/9.0f*w + pad;
			fy = y - s*0.5f + pad;

			nvgLineCap(vg, caps[i]);
			nvgLineJoin(vg, joins[j]);

			nvgStrokeWidth(vg, s*0.3f);
			nvgStrokeColor(vg, nvgRGBA(0,0,0,160) );
			nvgBeginPath(vg);
			nvgMoveTo(vg, fx+pts[0], fy+pts[1]);
			nvgLineTo(vg, fx+pts[2], fy+pts[3]);
			nvgLineTo(vg, fx+pts[4], fy+pts[5]);
			nvgLineTo(vg, fx+pts[6], fy+pts[7]);
			nvgStroke(vg);

			nvgLineCap(vg, NVGlineCap.NVG_BUTT);
			nvgLineJoin(vg, NVGlineCap.NVG_BEVEL);

			nvgStrokeWidth(vg, 1.0f);
			nvgStrokeColor(vg, nvgRGBA(0,192,255,255) );
			nvgBeginPath(vg);
			nvgMoveTo(vg, fx+pts[0], fy+pts[1]);
			nvgLineTo(vg, fx+pts[2], fy+pts[3]);
			nvgLineTo(vg, fx+pts[4], fy+pts[5]);
			nvgLineTo(vg, fx+pts[6], fy+pts[7]);
			nvgStroke(vg);
		}
	}

	nvgRestore(vg);
}

void drawBlendish(NVGcontext* _vg, float _x, float _y, float _w, float _h, float _t) {
	float x = _x;
	float y = _y;

	bndBackground(_vg, _x - 10.0f, _y - 10.0f, _w, _h);

	bndToolButton(_vg, x, y, 120.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_DEFAULT, BND_ICONID(6, 3), "Default");
	y += 25.0f;
	bndToolButton(_vg, x, y, 120.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_HOVER, BND_ICONID(6, 3), "Hovered");
	y += 25.0f;
	bndToolButton(_vg, x, y, 120.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_ACTIVE, BND_ICONID(6, 3), "Active");

	y += 40.0f;
	bndRadioButton(_vg, x, y, 80.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_DEFAULT, -1, "Default");
	y += 25.0f;
	bndRadioButton(_vg, x, y, 80.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_HOVER, -1, "Hovered");
	y += 25.0f;
	bndRadioButton(_vg, x, y, 80.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_ACTIVE, -1, "Active");

	y += 25.0f;
	bndLabel(_vg, x, y, 120.0f, BND_WIDGET_HEIGHT, -1, "Label:");
	y += BND_WIDGET_HEIGHT;
	bndChoiceButton(_vg, x, y, 80.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_DEFAULT, -1, "Default");
	y += 25.0f;
	bndChoiceButton(_vg, x, y, 80.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_HOVER, -1, "Hovered");
	y += 25.0f;
	bndChoiceButton(_vg, x, y, 80.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_ACTIVE, -1, "Active");

	y += 25.0f;
	float ry = y;
	float rx = x;

	y = _y;
	x += 130.0f;
	bndOptionButton(_vg, x, y, 120.0f, BND_WIDGET_HEIGHT, BNDwidgetState.BND_DEFAULT, "Default");
	y += 25.0f;
	bndOptionButton(_vg, x, y, 120.0f, BND_WIDGET_HEIGHT, BNDwidgetState.BND_HOVER, "Hovered");
	y += 25.0f;
	bndOptionButton(_vg, x, y, 120.0f, BND_WIDGET_HEIGHT, BNDwidgetState.BND_ACTIVE, "Active");

	y += 40.0f;
	bndNumberField(_vg, x, y, 120.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_DOWN, BNDwidgetState.BND_DEFAULT, "Top", "100");
	y += BND_WIDGET_HEIGHT - 2.0f;
	bndNumberField(_vg, x, y, 120.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_ALL, BNDwidgetState.BND_DEFAULT, "Center", "100");
	y += BND_WIDGET_HEIGHT - 2.0f;
	bndNumberField(_vg, x, y, 120.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_TOP, BNDwidgetState.BND_DEFAULT, "Bottom", "100");

	float mx = x - 30.0f;
	float my = y - 12.0f;
	float mw = 120.0f;
	bndMenuBackground(_vg, mx, my, mw, 120.0f, BNDcornerFlags.BND_CORNER_TOP);
	bndMenuLabel(_vg, mx, my, mw, BND_WIDGET_HEIGHT, -1, "Menu Title");
	my += BND_WIDGET_HEIGHT - 2.0f;
	bndMenuItem(_vg, mx, my, mw, BND_WIDGET_HEIGHT, BNDwidgetState.BND_DEFAULT, BND_ICONID(17, 3), "Default");
	my += BND_WIDGET_HEIGHT - 2.0f;
	bndMenuItem(_vg, mx, my, mw, BND_WIDGET_HEIGHT, BNDwidgetState.BND_HOVER, BND_ICONID(18, 3), "Hovered");
	my += BND_WIDGET_HEIGHT - 2.0f;
	bndMenuItem(_vg, mx, my, mw, BND_WIDGET_HEIGHT, BNDwidgetState.BND_ACTIVE, BND_ICONID(19, 3), "Active");

	y = _y;
	x += 130.0f;
	float ox = x;
	bndNumberField(_vg, x, y, 120.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_DEFAULT, "Default", "100");
	y += 25.0f;
	bndNumberField(_vg, x, y, 120.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_HOVER, "Hovered", "100");
	y += 25.0f;
	bndNumberField(_vg, x, y, 120.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_ACTIVE, "Active", "100");

	y += 40.0f;
	bndRadioButton(_vg, x, y, 60.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_RIGHT, BNDwidgetState.BND_DEFAULT, -1, "One");
	x += 60.0f - 1.0f;
	bndRadioButton(_vg, x, y, 60.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_ALL, BNDwidgetState.BND_DEFAULT, -1, "Two");
	x += 60.0f - 1.0f;
	bndRadioButton(_vg, x, y, 60.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_ALL, BNDwidgetState.BND_DEFAULT, -1, "Three");
	x += 60.0f - 1.0f;
	bndRadioButton(_vg, x, y, 60.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_LEFT, BNDwidgetState.BND_ACTIVE, -1, "Butts");

	x = ox;
	y += 40.0f;
	float progress_value = fmod(_t / 10.0f, 1.0f);
	string progress_label = text(cast(int)(progress_value * 100 + 0.5f)) ~ "%";
    
	bndSlider(_vg, x, y, 240, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_DEFAULT, progress_value, "Default", toStringz(progress_label));
	y += 25.0f;
	bndSlider(_vg, x, y, 240, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_HOVER, progress_value, "Hovered", toStringz(progress_label));
	y += 25.0f;
	bndSlider(_vg, x, y, 240, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_ACTIVE, progress_value, "Active", toStringz(progress_label));

	float rw = x + 240.0f - rx;
	float s_offset = sin(_t / 2.0f) * 0.5f + 0.5f;
	float s_size = cos(_t / 3.11f) * 0.5f + 0.5f;

	bndScrollBar(_vg, rx, ry, rw, BND_SCROLLBAR_HEIGHT, BNDwidgetState.BND_DEFAULT, s_offset, s_size);
	ry += 20.0f;
	bndScrollBar(_vg, rx, ry, rw, BND_SCROLLBAR_HEIGHT, BNDwidgetState.BND_HOVER, s_offset, s_size);
	ry += 20.0f;
	bndScrollBar(_vg, rx, ry, rw, BND_SCROLLBAR_HEIGHT, BNDwidgetState.BND_ACTIVE, s_offset, s_size);

	string edit_text = "The quick brown fox";
	int textlen = cast(int)(edit_text.length + 1);
	int t = cast(int)(_t * 2);
	int idx1 = (t / textlen) % textlen;
	int idx2 = idx1 + (t % (textlen - idx1) );

	ry += 25.0f;
	bndTextField(_vg, rx, ry, 240.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_DEFAULT, -1, toStringz(edit_text), idx1, idx2);
	ry += 25.0f;
	bndTextField(_vg, rx, ry, 240.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_HOVER, -1, toStringz(edit_text), idx1, idx2);
	ry += 25.0f;
	bndTextField(_vg, rx, ry, 240.0f, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_NONE, BNDwidgetState.BND_ACTIVE, -1, toStringz(edit_text), idx1, idx2);

	rx += rw + 20.0f;
	ry = _y;
	bndScrollBar(_vg, rx, ry, BND_SCROLLBAR_WIDTH, 240.0f, BNDwidgetState.BND_DEFAULT, s_offset, s_size);
	rx += 20.0f;
	bndScrollBar(_vg, rx, ry, BND_SCROLLBAR_WIDTH, 240.0f, BNDwidgetState.BND_HOVER, s_offset, s_size);
	rx += 20.0f;
	bndScrollBar(_vg, rx, ry, BND_SCROLLBAR_WIDTH, 240.0f, BNDwidgetState.BND_ACTIVE, s_offset, s_size);

	x = ox;
	y += 40.0f;
	bndToolButton(_vg, x, y, BND_TOOL_WIDTH, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_RIGHT, BNDwidgetState.BND_DEFAULT, BND_ICONID(0, 10), null);
	x += BND_TOOL_WIDTH - 1;
	bndToolButton(_vg, x, y, BND_TOOL_WIDTH, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_ALL, BNDwidgetState.BND_DEFAULT, BND_ICONID(1, 10), null);
	x += BND_TOOL_WIDTH - 1;
	bndToolButton(_vg, x, y, BND_TOOL_WIDTH, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_ALL, BNDwidgetState.BND_DEFAULT, BND_ICONID(2, 10), null);
	x += BND_TOOL_WIDTH - 1;
	bndToolButton(_vg, x, y, BND_TOOL_WIDTH, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_ALL, BNDwidgetState.BND_DEFAULT, BND_ICONID(3, 10), null);
	x += BND_TOOL_WIDTH - 1;
	bndToolButton(_vg, x, y, BND_TOOL_WIDTH, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_ALL, BNDwidgetState.BND_DEFAULT, BND_ICONID(4, 10), null);
	x += BND_TOOL_WIDTH - 1;
	bndToolButton(_vg, x, y, BND_TOOL_WIDTH, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_LEFT, BNDwidgetState.BND_DEFAULT, BND_ICONID(5, 10), null);
	x += BND_TOOL_WIDTH - 1;
	x += 5.0f;
	bndRadioButton(_vg, x, y, BND_TOOL_WIDTH, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_RIGHT, BNDwidgetState.BND_DEFAULT, BND_ICONID(0, 11), null);
	x += BND_TOOL_WIDTH - 1;
	bndRadioButton(_vg, x, y, BND_TOOL_WIDTH, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_ALL, BNDwidgetState.BND_DEFAULT, BND_ICONID(1, 11), null);
	x += BND_TOOL_WIDTH - 1;
	bndRadioButton(_vg, x, y, BND_TOOL_WIDTH, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_ALL, BNDwidgetState.BND_DEFAULT, BND_ICONID(2, 11), null);
	x += BND_TOOL_WIDTH - 1;
	bndRadioButton(_vg, x, y, BND_TOOL_WIDTH, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_ALL, BNDwidgetState.BND_DEFAULT, BND_ICONID(3, 11), null);
	x += BND_TOOL_WIDTH - 1;
	bndRadioButton(_vg, x, y, BND_TOOL_WIDTH, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_ALL, BNDwidgetState.BND_ACTIVE, BND_ICONID(4, 11), null);
	x += BND_TOOL_WIDTH - 1;
	bndRadioButton(_vg, x, y, BND_TOOL_WIDTH, BND_WIDGET_HEIGHT, BNDcornerFlags.BND_CORNER_LEFT, BNDwidgetState.BND_DEFAULT, BND_ICONID(5, 11), null);
}

struct DemoData {
	int fontNormal, fontBold, fontIcons;
	int[12] images;
}

int loadDemoData(NVGcontext* vg, DemoData* data) {
	for (uint ii = 0; ii < 12; ++ii) {
		string file = "images/image"~text(ii+1)~".jpg";
		data.images[ii] = nvgCreateImage(vg, toStringz(file), 0);
		if (data.images[ii] == 0) {
			printf("Could not load %s.\n", toStringz(file));
			return -1;
		}
	}

	data.fontIcons = nvgCreateFont(vg, "icons", "font/entypo.ttf");
	if (data.fontIcons == -1) {
		printf("Could not add font icons.\n");
		return -1;
	}

	data.fontNormal = nvgCreateFont(vg, "sans", "font/roboto-regular.ttf");
	if (data.fontNormal == -1) {
		printf("Could not add font italic.\n");
		return -1;
	}

	data.fontBold = nvgCreateFont(vg, "sans-bold", "font/roboto-bold.ttf");
	if (data.fontBold == -1) {
		printf("Could not add font bold.\n");
		return -1;
	}

	return 0;
}

void freeDemoData(NVGcontext* vg, DemoData* data) {
	if (vg == null)
		return;

	for(int i = 0; i < 12; i++)
		nvgDeleteImage(vg, data.images[i]);
}

float fround(float x) {
    return floor(x + 0.5f);
}

void drawParagraph(NVGcontext* vg, float x, float y, float width, float height, float mx, float my) {
	NVGtextRow[3] rows;
	NVGglyphPosition[100] glyphs;
	string text = "This is longer chunk of text.\n  \n  Would have used lorem ipsum but she    was busy jumping over the lazy dog with the fox and all the men who came to the aid of the party.";
	const(char)* start;
	const(char)* end;
	int nrows, i, nglyphs, j, lnum = 0;
	float lineh;
	float caretx, px;
	float[4] bounds;
	float gx = 0.0f, gy = 0.0f;
	int gutter = 0;

	nvgSave(vg);

	nvgFontSize(vg, 18.0f);
	nvgFontFace(vg, "sans");
	nvgTextAlign(vg, NVGalign.NVG_ALIGN_LEFT|NVGalign.NVG_ALIGN_TOP);
	nvgTextMetrics(vg, null, null, &lineh);

	// The text break API can be used to fill a large buffer of rows,
	// or to iterate over the text just few lines (or just one) at a time.
	// The "next" variable of the last returned item tells where to continue.
	start = text.ptr;
	end = text.ptr + text.length;
	for (nrows = nvgTextBreakLines(vg, start, end, width, rows.ptr, 3); 0 != nrows; nrows = nvgTextBreakLines(vg, start, end, width, rows.ptr, 3)) {
		for (i = 0; i < nrows; i++) {
			NVGtextRow* row = &rows[i];
			int hit = mx > x && mx < (x+width) && my >= y && my < (y+lineh);

			nvgBeginPath(vg);
			nvgFillColor(vg, nvgRGBA(255,255,255,hit?64:8) );
			nvgRect(vg, x, y, row.width, lineh);
			nvgFill(vg);

			nvgFillColor(vg, nvgRGBA(255,255,255,255) );
			nvgText(vg, x, y, row.start, row.end);

			if (hit) {
				caretx = (mx < x+row.width/2) ? x : x+row.width;
				px = x;
				nglyphs = nvgTextGlyphPositions(vg, x, y, row.start, row.end, glyphs.ptr, 100);
				for (j = 0; j < nglyphs; j++) {
					float x0 = glyphs[j].x;
					float x1 = (j+1 < nglyphs) ? glyphs[j+1].x : x+row.width;
					float tgx = x0 * 0.3f + x1 * 0.7f;
					if (mx >= px && mx < tgx)
						caretx = glyphs[j].x;
					px = tgx;
				}
				nvgBeginPath(vg);
				nvgFillColor(vg, nvgRGBA(255,192,0,255) );
				nvgRect(vg, caretx, y, 1, lineh);
				nvgFill(vg);

				gutter = lnum+1;
				gx = x - 10;
				gy = y + lineh/2;
			}
			lnum++;
			y += lineh;
		}
		// Keep going...
		start = rows[nrows-1].next;
	}

	if (gutter)	{
		string txt = to!string(gutter);
		nvgFontSize(vg, 13.0f);
		nvgTextAlign(vg, NVGalign.NVG_ALIGN_RIGHT|NVGalign.NVG_ALIGN_MIDDLE);
        
		nvgTextBounds(vg, gx,gy, toStringz(txt), null, bounds.ptr);

		nvgBeginPath(vg);
		nvgFillColor(vg, nvgRGBA(255,192,0,255) );
		nvgRoundedRect(vg
			, fround(bounds[0])-4.0f
			, fround(bounds[1])-2.0f
			, fround(bounds[2]-bounds[0])+8.0f
			, fround(bounds[3]-bounds[1])+4.0f
			, (fround(bounds[3]-bounds[1])+4.0f)/2.0f-1.0f
			);
		nvgFill(vg);

		nvgFillColor(vg, nvgRGBA(32,32,32,255) );
		nvgText(vg, gx,gy, toStringz(txt), null);
	}

	y += 20.0f;

	nvgFontSize(vg, 13.0f);
	nvgTextAlign(vg, NVGalign.NVG_ALIGN_LEFT|NVGalign.NVG_ALIGN_TOP);
	nvgTextLineHeight(vg, 1.2f);

	nvgTextBoxBounds(vg, x,y, 150, "Hover your mouse over the text to see calculated caret position.", null, bounds.ptr);
	nvgBeginPath(vg);
	nvgFillColor(vg, nvgRGBA(220,220,220,255) );
	nvgRoundedRect(vg
		, fround(bounds[0]-2.0f)
		, fround(bounds[1]-2.0f)
		, fround(bounds[2]-bounds[0])+4.0f
		, fround(bounds[3]-bounds[1])+4.0f
		, 3.0f
		);
	px = cast(float)(cast(int)((bounds[2]+bounds[0])/2));
	nvgMoveTo(vg, px,bounds[1] - 10);
	nvgLineTo(vg, px+7,bounds[1]+1);
	nvgLineTo(vg, px-7,bounds[1]+1);
	nvgFill(vg);

	nvgFillColor(vg, nvgRGBA(0,0,0,220) );
	nvgTextBox(vg, x,y, 150, "Hover your mouse over the text to see calculated caret position.", null);

	nvgRestore(vg);
}

void drawWidths(NVGcontext* vg, float x, float y, float width) {
	nvgSave(vg);

	nvgStrokeColor(vg, nvgRGBA(0,0,0,255) );

	for (int ii = 0; ii < 20; ++ii) {
		float w = (ii+0.5f)*0.1f;
		nvgStrokeWidth(vg, w);
		nvgBeginPath(vg);
		nvgMoveTo(vg, x,y);
		nvgLineTo(vg, x+width,y+width*0.3f);
		nvgStroke(vg);
		y += 10;
	}

	nvgRestore(vg);
}


void renderDemo(NVGcontext* vg, float mx, float my, float width, float height, float t, int blowup, DemoData* data) {
    float x,y,popx,popy;

	drawEyes(vg, width-800, height-240, 150, 100, mx, my, t);
	drawParagraph(vg, width - 550, 35, 150, 100, mx, my);
	drawGraph(vg, 0, height/2, width, height/2, t);

	drawColorwheel(vg, width-350, 35, 250.0f, 250.0f, t);

	// Line joints
	drawLines(vg, 50, height-50, 600, 35, t);

	nvgSave(vg);
	if (blowup)
	{
		nvgRotate(vg, sin(t*0.3f)*5.0f/180.0f*NVG_PI);
		nvgScale(vg, 2.0f, 2.0f);
	}

	// Line width.
	drawWidths(vg, width-50, 35, 30);

	// Widgets.
	x = width-520; y = height-420;
	drawWindow(vg, "Widgets `n Stuff", x, y, 300, 400);
	x += 10;
	y += 45;
	drawSearchBox(vg, "Search", x,y,280,25);
	y += 40;
	drawDropDown(vg, "Effects", x,y,280,28);
	popx = x + 300;
	popy = y + 14;
	y += 45;

	// Form
	drawLabel(vg, "Login", x,y, 280,20);
	y += 25;
	drawEditBox(vg, "Email",  x,y, 280,28);
	y += 35;
	drawEditBox(vg, "Password", x,y, 280,28);
	y += 38;
	drawCheckBox(vg, "Remember me", x,y, 140,28);
	drawButton(vg, ICON_LOGIN, "Sign in", x+138, y, 140, 28, nvgRGBA(0,96,128,255));
	y += 45;

	// Slider
	drawLabel(vg, "Diameter", x,y, 280,20);
	y += 25;
	drawEditBoxNum(vg, "123.00", "px", x+180,y, 100,28);
	drawSlider(vg, 0.4f, x,y, 170,28);
	y += 55;

	drawButton(vg, ICON_TRASH, "Delete", x, y, 160, 28, nvgRGBA(128,16,8,255));
	drawButton(vg, 0, "Cancel", x+170, y, 110, 28, nvgRGBA(0,0,0,0));

	// Thumbnails box
	drawThumbnails(vg, popx, popy-30, 160, 300, data.images.ptr, 12, t);

	// Blendish
	drawBlendish(vg, 10, 62, 600.0f, 420.0f, t);

	nvgRestore(vg);
}

class ExampleNanoVG {
    private {
        uint m_width = 1280;
        uint m_height = 720;
        uint m_debug = BGFX_DEBUG_TEXT;
        uint m_reset = BGFX_RESET_VSYNC;
        long m_timeOffset;
        //ulong m_timeOffset;
        NVGcontext* m_nvg;
        
        SDL_Window* m_window;
        
        DemoData m_data;
        
        int[2] m_mouse_pos;
    }
    
    void init(bgfx.RendererType.Enum m_type = bgfx.RendererType.Enum.Count, ushort m_pciId = BGFX_PCI_ID_NONE) {
        try { 
            DerelictSDL2.load(SharedLibVersion(2, 0, 2)); 
        } catch(Exception e) { 
            throw new Exception("Error loading SDL2 lib. "~e.msg); 
        }
        
        if(SDL_Init(SDL_INIT_VIDEO) < 0) 
		    throw new Exception("Failed to initialize SDL: " ~ text(SDL_GetError()));
        
        // Set OpenGL version
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
            
        // Set OpenGL attributes
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
            
        SDL_GL_SetAttribute(SDL_GL_ACCELERATED_VISUAL, 1);
        
        m_window = SDL_CreateWindow("bgfx example - nanovg", 100, 100, m_width, m_height, SDL_WINDOW_OPENGL|SDL_WINDOW_SHOWN);
        if (!m_window)
            throw new Exception("Failed to create a SDL window: " ~ text(SDL_GetError()));
        
        SDL_GL_SetSwapInterval(1);
        
        // Set platform data
        
        SDL_SysWMinfo wmi;
        SDL_VERSION(&wmi.version_);
            
        if (!SDL_GetWindowWMInfo(m_window, &wmi)) {
            throw new Exception("Filed to retrieve SDL window info.");
        }
        
        PlatformData pd; 
        
        version(linux) {
            pd.ndt = cast(void*)wmi.info.x11.display;
            pd.nwh = cast(void*)wmi.info.x11.window;
        } else {
            throw new Exception("Implement this platform.");
        }
        
        pd.context = null;
        pd.backBuffer = null;
        pd.backBufferDS = null;
        
        setPlatformData(pd);
        
        // init bgfx
    
        bgfx.init();
        bgfx.reset(m_width, m_height, m_reset);
        
        // Enable debug text.
		bgfx.setDebug(m_debug);

		// Set view 0 clear state.
		bgfx.setViewClear(0
			, BGFX_CLEAR_COLOR|BGFX_CLEAR_DEPTH
			, 0x303030ff
			, 1.0f
			, 0
			);
            
        //imguiCreate();

		m_nvg = nvgCreate(1, 0);
		bgfx.setViewSeq(0, true);

		loadDemoData(m_nvg, &m_data);

		bndSetFont(nvgCreateFont(m_nvg, "droidsans", "font/droidsans.ttf"));
		bndSetIconImage(nvgCreateImage(m_nvg, "images/blender_icons16.png", 0));

		m_timeOffset = MonoTime.currTime.ticks;
    }
    
    void shutdown() {
        freeDemoData(m_nvg, &m_data);

		nvgDelete(m_nvg);

		//imguiDestroy();

		// Shutdown bgfx.
		bgfx.shutdown();
    }
    
    void update() {
        long now = MonoTime.currTime.ticks;
        auto time = (now - m_timeOffset) / cast(double)MonoTime.ticksPerSecond;
        
        // Set view 0 default viewport.
        bgfx.setViewRect(0, 0, 0, cast(ushort)m_width, cast(ushort)m_height);

        // This dummy draw call is here to make sure that view 0 is cleared
        // if no other draw calls are submitted to view 0.
        bgfx.touch(0);

        bgfx.dbgTextClear();
	    bgfx.dbgTextPrintf(0, 1, 0x4f, "bgfx/examples/20-nanovg");
		bgfx.dbgTextPrintf(0, 2, 0x6f, "Description: NanoVG is small antialiased vector graphics rendering library.");

        nvgBeginFrame(m_nvg, m_width, m_height, 1.0f);
        
        renderDemo(m_nvg, m_mouse_pos[0], m_mouse_pos[1], cast(float)m_width, cast(float)m_height, time, 0, &m_data);
        
        nvgEndFrame(m_nvg);

        // Advance to next frame. Rendering thread will be kicked to
		// process submitted rendering primitives.
		bgfx.frame();
    }
    
    bool run() {
		bool isRunning = true;
		SDL_Event sdl_event;
		while (isRunning && SDL_PollEvent(&sdl_event)) {
			switch(sdl_event.type) {
                case SDL_MOUSEMOTION: {
                    
                    m_mouse_pos = [sdl_event.motion.x, sdl_event.motion.y];
					
					break;
				}
                case SDL_QUIT: {
	               isRunning = false;
	               break;
	            }
				default: {
					
				}
			}
		}
		return isRunning;
	}
    
    void start() {
        while(run()) {
            update();
        }
    }
}

void main() {
	auto example = new ExampleNanoVG();
    example.init();
    example.start();
}
