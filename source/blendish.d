module blendish;

private {
    import bgfx_extras.nanovg;
    import std.math;
 }


/*
Blendish - Blender 2.5 UI based theming functions for NanoVG

Copyright (c) 2014 Leonard Ritter <leonard.ritter@duangle.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

/*

Revision 6 (2014-09-21)

Summary
-------

Blendish is a small collection of drawing functions for NanoVG, designed to 
replicate the look of the Blender 2.5+ User Interface. You can use these 
functions to theme your UI library. Several metric constants for faithful
reproduction are also included.

Blendish supports the original Blender icon sheet; As the licensing of Blenders
icons is unclear, they are not included in Blendishes repository, but a SVG
template, "icons_template.svg" is provided, which you can use to build your own
icon sheet.

To use icons, you must first load the icon sheet using one of the 
nvgCreateImage*() functions and then pass the image handle to bndSetIconImage();
otherwise, no icons will be drawn. See bndSetIconImage() for more information.

Blendish will not render text until a suitable UI font has been passed to
bndSetFont() has been called. See bndSetFont() for more information.


Drawbacks
---------

There is no support for varying dpi resolutions yet. The library is hardcoded
to the equivalent of 72 dpi in the Blender system settings.

Support for label truncation is missing. Text rendering breaks when widgets are
too short to contain their labels.

Usage
-----

To use this header file in implementation mode, define BLENDISH_IMPLEMENTATION
before including blendish.h, otherwise the file will be in header-only mode.

*/

// describes the theme used to draw a single widget or widget box;
// these values correspond to the same values that can be retrieved from
// the Theme panel in the Blender preferences
struct BNDwidgetTheme {
    // color of widget box outline
    NVGcolor outlineColor;
    // color of widget item (meaning changes depending on class)
    NVGcolor itemColor;
    // fill color of widget box
    NVGcolor innerColor;
    // fill color of widget box when active
    NVGcolor innerSelectedColor;
    // color of text label
    NVGcolor textColor;
    // color of text label when active
    NVGcolor textSelectedColor;
    // delta modifier for upper part of gradient (-100 to 100)
    int shadeTop;
    // delta modifier for lower part of gradient (-100 to 100)
    int shadeDown;
}

// describes the theme used to draw nodes
struct BNDnodeTheme {
    // inner color of selected node (and downarrow)
    NVGcolor nodeSelectedColor;
    // outline of wires
    NVGcolor wiresColor;
    // color of text label when active
    NVGcolor textSelectedColor;
    
    // inner color of active node (and dragged wire)
    NVGcolor activeNodeColor;
    // color of selected wire
    NVGcolor wireSelectColor;
    // color of background of node
    NVGcolor nodeBackdropColor;
    
    // how much a noodle curves (0 to 10)
    int noodleCurving;
}

// describes the theme used to draw widgets
struct BNDtheme {
    // the background color of panels and windows
    NVGcolor backgroundColor;
    // theme for labels
    BNDwidgetTheme regularTheme;
    // theme for tool buttons
    BNDwidgetTheme toolTheme;
    // theme for radio buttons
    BNDwidgetTheme radioTheme;
    // theme for text fields
    BNDwidgetTheme textFieldTheme;
    // theme for option buttons (checkboxes)
    BNDwidgetTheme optionTheme;
    // theme for choice buttons (comboboxes)
    // Blender calls them "menu buttons"
    BNDwidgetTheme choiceTheme;
    // theme for number fields
    BNDwidgetTheme numberFieldTheme;
    // theme for slider controls
    BNDwidgetTheme sliderTheme;
    // theme for scrollbars
    BNDwidgetTheme scrollBarTheme;
    // theme for tooltips
    BNDwidgetTheme tooltipTheme;
    // theme for menu backgrounds
    BNDwidgetTheme menuTheme;
    // theme for menu items
    BNDwidgetTheme menuItemTheme;
    // theme for nodes
    BNDnodeTheme nodeTheme;
}

// how text on a control is aligned
enum BNDtextAlignment {
    BND_LEFT = 0,
    BND_CENTER,
}

// states altering the styling of a widget
enum BNDwidgetState {
    // not interacting
    BND_DEFAULT = 0,
    // the mouse is hovering over the control
    BND_HOVER,
    // the widget is activated (pressed) or in an active state (toggled)
    BND_ACTIVE
}

// flags indicating which corners are sharp (for grouping widgets)
enum BNDcornerFlags {
    // all corners are round
    BND_CORNER_NONE = 0,
    // sharp top left corner
    BND_CORNER_TOP_LEFT = 1,
    // sharp top right corner
    BND_CORNER_TOP_RIGHT = 2,
    // sharp bottom right corner
    BND_CORNER_DOWN_RIGHT = 4,
    // sharp bottom left corner
    BND_CORNER_DOWN_LEFT = 8,
    // all corners are sharp; 
    // you can invert a set of flags using ^= BND_CORNER_ALL
    BND_CORNER_ALL = 0xF,
    // top border is sharp
    BND_CORNER_TOP = 3,
    // bottom border is sharp
    BND_CORNER_DOWN = 0xC,
    // left border is sharp
    BND_CORNER_LEFT = 9,
    // right border is sharp
    BND_CORNER_RIGHT = 6
}

// build an icon ID from two coordinates into the icon sheet, where
// (0,0) designates the upper-leftmost icon, (1,0) the one right next to it,
// and so on.
int BND_ICONID(int x, int y) { return x|(y<<8); }
// alpha of disabled widget groups
// can be used in conjunction with nvgGlobalAlpha()
enum BND_DISABLED_ALPHA = 0.5;

enum {
	// default widget height
	BND_WIDGET_HEIGHT = 21,
	// default toolbutton width (if icon only)
	BND_TOOL_WIDTH = 20,

	// default radius of node ports
	BND_NODE_PORT_RADIUS = 5,
	// top margin of node content
	BND_NODE_MARGIN_TOP = 25,
	// bottom margin of node content
	BND_NODE_MARGIN_DOWN = 5,
	// left and right margin of node content
	BND_NODE_MARGIN_SIDE = 10,
	// height of node title bar
	BND_NODE_TITLE_HEIGHT = 20,
	// width of node title arrow click area
	BND_NODE_ARROW_AREA_WIDTH = 20,

	// size of splitter corner click area
	BND_SPLITTER_AREA_SIZE = 12,

	// width of vertical scrollbar
	BND_SCROLLBAR_WIDTH = 13,
	// height of horizontal scrollbar
	BND_SCROLLBAR_HEIGHT = 14,

	// default vertical spacing
	BND_VSPACING = 1,
	// default vertical spacing between groups
	BND_VSPACING_GROUP = 8,
	// default horizontal spacing
	BND_HSPACING = 8,
}

enum BNDicon {
	BND_ICON_NONE = BND_ICONID(0,29),
	BND_ICON_QUESTION = BND_ICONID(1,29),
	BND_ICON_ERROR = BND_ICONID(2,29),
	BND_ICON_CANCEL = BND_ICONID(3,29),
	BND_ICON_TRIA_RIGHT = BND_ICONID(4,29),
	BND_ICON_TRIA_DOWN = BND_ICONID(5,29),
	BND_ICON_TRIA_LEFT = BND_ICONID(6,29),
	BND_ICON_TRIA_UP = BND_ICONID(7,29),
	BND_ICON_ARROW_LEFTRIGHT = BND_ICONID(8,29),
	BND_ICON_PLUS = BND_ICONID(9,29),
	BND_ICON_DISCLOSURE_TRI_DOWN = BND_ICONID(10,29),
	BND_ICON_DISCLOSURE_TRI_RIGHT = BND_ICONID(11,29),
	BND_ICON_RADIOBUT_OFF = BND_ICONID(12,29),
	BND_ICON_RADIOBUT_ON = BND_ICONID(13,29),
	BND_ICON_MENU_PANEL = BND_ICONID(14,29),
	BND_ICON_BLENDER = BND_ICONID(15,29),
	BND_ICON_GRIP = BND_ICONID(16,29),
	BND_ICON_DOT = BND_ICONID(17,29),
	BND_ICON_COLLAPSEMENU = BND_ICONID(18,29),
	BND_ICON_X = BND_ICONID(19,29),
	BND_ICON_GO_LEFT = BND_ICONID(21,29),
	BND_ICON_PLUG = BND_ICONID(22,29),
	BND_ICON_UI = BND_ICONID(23,29),
	BND_ICON_NODE = BND_ICONID(24,29),
	BND_ICON_NODE_SEL = BND_ICONID(25,29),

	BND_ICON_FULLSCREEN = BND_ICONID(0,28),
	BND_ICON_SPLITSCREEN = BND_ICONID(1,28),
	BND_ICON_RIGHTARROW_THIN = BND_ICONID(2,28),
	BND_ICON_BORDERMOVE = BND_ICONID(3,28),
	BND_ICON_VIEWZOOM = BND_ICONID(4,28),
	BND_ICON_ZOOMIN = BND_ICONID(5,28),
	BND_ICON_ZOOMOUT = BND_ICONID(6,28),
	BND_ICON_PANEL_CLOSE = BND_ICONID(7,28),
	BND_ICON_COPY_ID = BND_ICONID(8,28),
	BND_ICON_EYEDROPPER = BND_ICONID(9,28),
	BND_ICON_LINK_AREA = BND_ICONID(10,28),
	BND_ICON_AUTO = BND_ICONID(11,28),
	BND_ICON_CHECKBOX_DEHLT = BND_ICONID(12,28),
	BND_ICON_CHECKBOX_HLT = BND_ICONID(13,28),
	BND_ICON_UNLOCKED = BND_ICONID(14,28),
	BND_ICON_LOCKED = BND_ICONID(15,28),
	BND_ICON_UNPINNED = BND_ICONID(16,28),
	BND_ICON_PINNED = BND_ICONID(17,28),
	BND_ICON_SCREEN_BACK = BND_ICONID(18,28),
	BND_ICON_RIGHTARROW = BND_ICONID(19,28),
	BND_ICON_DOWNARROW_HLT = BND_ICONID(20,28),
	BND_ICON_DOTSUP = BND_ICONID(21,28),
	BND_ICON_DOTSDOWN = BND_ICONID(22,28),
	BND_ICON_LINK = BND_ICONID(23,28),
	BND_ICON_INLINK = BND_ICONID(24,28),
	BND_ICON_PLUGIN = BND_ICONID(25,28),

	BND_ICON_HELP = BND_ICONID(0,27),
	BND_ICON_GHOST_ENABLED = BND_ICONID(1,27),
	BND_ICON_COLOR = BND_ICONID(2,27),
	BND_ICON_LINKED = BND_ICONID(3,27),
	BND_ICON_UNLINKED = BND_ICONID(4,27),
	BND_ICON_HAND = BND_ICONID(5,27),
	BND_ICON_ZOOM_ALL = BND_ICONID(6,27),
	BND_ICON_ZOOM_SELECTED = BND_ICONID(7,27),
	BND_ICON_ZOOM_PREVIOUS = BND_ICONID(8,27),
	BND_ICON_ZOOM_IN = BND_ICONID(9,27),
	BND_ICON_ZOOM_OUT = BND_ICONID(10,27),
	BND_ICON_RENDER_REGION = BND_ICONID(11,27),
	BND_ICON_BORDER_RECT = BND_ICONID(12,27),
	BND_ICON_BORDER_LASSO = BND_ICONID(13,27),
	BND_ICON_FREEZE = BND_ICONID(14,27),
	BND_ICON_STYLUS_PRESSURE = BND_ICONID(15,27),
	BND_ICON_GHOST_DISABLED = BND_ICONID(16,27),
	BND_ICON_NEW = BND_ICONID(17,27),
	BND_ICON_FILE_TICK = BND_ICONID(18,27),
	BND_ICON_QUIT = BND_ICONID(19,27),
	BND_ICON_URL = BND_ICONID(20,27),
	BND_ICON_RECOVER_LAST = BND_ICONID(21,27),
	BND_ICON_FULLSCREEN_ENTER = BND_ICONID(23,27),
	BND_ICON_FULLSCREEN_EXIT = BND_ICONID(24,27),
	BND_ICON_BLANK1 = BND_ICONID(25,27),

	BND_ICON_LAMP = BND_ICONID(0,26),
	BND_ICON_MATERIAL = BND_ICONID(1,26),
	BND_ICON_TEXTURE = BND_ICONID(2,26),
	BND_ICON_ANIM = BND_ICONID(3,26),
	BND_ICON_WORLD = BND_ICONID(4,26),
	BND_ICON_SCENE = BND_ICONID(5,26),
	BND_ICON_EDIT = BND_ICONID(6,26),
	BND_ICON_GAME = BND_ICONID(7,26),
	BND_ICON_RADIO = BND_ICONID(8,26),
	BND_ICON_SCRIPT = BND_ICONID(9,26),
	BND_ICON_PARTICLES = BND_ICONID(10,26),
	BND_ICON_PHYSICS = BND_ICONID(11,26),
	BND_ICON_SPEAKER = BND_ICONID(12,26),
	BND_ICON_TEXTURE_SHADED = BND_ICONID(13,26),

	BND_ICON_VIEW3D = BND_ICONID(0,25),
	BND_ICON_IPO = BND_ICONID(1,25),
	BND_ICON_OOPS = BND_ICONID(2,25),
	BND_ICON_BUTS = BND_ICONID(3,25),
	BND_ICON_FILESEL = BND_ICONID(4,25),
	BND_ICON_IMAGE_COL = BND_ICONID(5,25),
	BND_ICON_INFO = BND_ICONID(6,25),
	BND_ICON_SEQUENCE = BND_ICONID(7,25),
	BND_ICON_TEXT = BND_ICONID(8,25),
	BND_ICON_IMASEL = BND_ICONID(9,25),
	BND_ICON_SOUND = BND_ICONID(10,25),
	BND_ICON_ACTION = BND_ICONID(11,25),
	BND_ICON_NLA = BND_ICONID(12,25),
	BND_ICON_SCRIPTWIN = BND_ICONID(13,25),
	BND_ICON_TIME = BND_ICONID(14,25),
	BND_ICON_NODETREE = BND_ICONID(15,25),
	BND_ICON_LOGIC = BND_ICONID(16,25),
	BND_ICON_CONSOLE = BND_ICONID(17,25),
	BND_ICON_PREFERENCES = BND_ICONID(18,25),
	BND_ICON_CLIP = BND_ICONID(19,25),
	BND_ICON_ASSET_MANAGER = BND_ICONID(20,25),

	BND_ICON_OBJECT_DATAMODE = BND_ICONID(0,24),
	BND_ICON_EDITMODE_HLT = BND_ICONID(1,24),
	BND_ICON_FACESEL_HLT = BND_ICONID(2,24),
	BND_ICON_VPAINT_HLT = BND_ICONID(3,24),
	BND_ICON_TPAINT_HLT = BND_ICONID(4,24),
	BND_ICON_WPAINT_HLT = BND_ICONID(5,24),
	BND_ICON_SCULPTMODE_HLT = BND_ICONID(6,24),
	BND_ICON_POSE_HLT = BND_ICONID(7,24),
	BND_ICON_PARTICLEMODE = BND_ICONID(8,24),
	BND_ICON_LIGHTPAINT = BND_ICONID(9,24),

	BND_ICON_SCENE_DATA = BND_ICONID(0,23),
	BND_ICON_RENDERLAYERS = BND_ICONID(1,23),
	BND_ICON_WORLD_DATA = BND_ICONID(2,23),
	BND_ICON_OBJECT_DATA = BND_ICONID(3,23),
	BND_ICON_MESH_DATA = BND_ICONID(4,23),
	BND_ICON_CURVE_DATA = BND_ICONID(5,23),
	BND_ICON_META_DATA = BND_ICONID(6,23),
	BND_ICON_LATTICE_DATA = BND_ICONID(7,23),
	BND_ICON_LAMP_DATA = BND_ICONID(8,23),
	BND_ICON_MATERIAL_DATA = BND_ICONID(9,23),
	BND_ICON_TEXTURE_DATA = BND_ICONID(10,23),
	BND_ICON_ANIM_DATA = BND_ICONID(11,23),
	BND_ICON_CAMERA_DATA = BND_ICONID(12,23),
	BND_ICON_PARTICLE_DATA = BND_ICONID(13,23),
	BND_ICON_LIBRARY_DATA_DIRECT = BND_ICONID(14,23),
	BND_ICON_GROUP = BND_ICONID(15,23),
	BND_ICON_ARMATURE_DATA = BND_ICONID(16,23),
	BND_ICON_POSE_DATA = BND_ICONID(17,23),
	BND_ICON_BONE_DATA = BND_ICONID(18,23),
	BND_ICON_CONSTRAINT = BND_ICONID(19,23),
	BND_ICON_SHAPEKEY_DATA = BND_ICONID(20,23),
	BND_ICON_CONSTRAINT_BONE = BND_ICONID(21,23),
	BND_ICON_CAMERA_STEREO = BND_ICONID(22,23),
	BND_ICON_PACKAGE = BND_ICONID(23,23),
	BND_ICON_UGLYPACKAGE = BND_ICONID(24,23),

	BND_ICON_BRUSH_DATA = BND_ICONID(0,22),
	BND_ICON_IMAGE_DATA = BND_ICONID(1,22),
	BND_ICON_FILE = BND_ICONID(2,22),
	BND_ICON_FCURVE = BND_ICONID(3,22),
	BND_ICON_FONT_DATA = BND_ICONID(4,22),
	BND_ICON_RENDER_RESULT = BND_ICONID(5,22),
	BND_ICON_SURFACE_DATA = BND_ICONID(6,22),
	BND_ICON_EMPTY_DATA = BND_ICONID(7,22),
	BND_ICON_SETTINGS = BND_ICONID(8,22),
	BND_ICON_RENDER_ANIMATION = BND_ICONID(9,22),
	BND_ICON_RENDER_STILL = BND_ICONID(10,22),
	BND_ICON_BOIDS = BND_ICONID(12,22),
	BND_ICON_STRANDS = BND_ICONID(13,22),
	BND_ICON_LIBRARY_DATA_INDIRECT = BND_ICONID(14,22),
	BND_ICON_GREASEPENCIL = BND_ICONID(15,22),
	BND_ICON_LINE_DATA = BND_ICONID(16,22),
	BND_ICON_GROUP_BONE = BND_ICONID(18,22),
	BND_ICON_GROUP_VERTEX = BND_ICONID(19,22),
	BND_ICON_GROUP_VCOL = BND_ICONID(20,22),
	BND_ICON_GROUP_UVS = BND_ICONID(21,22),
	BND_ICON_RNA = BND_ICONID(24,22),
	BND_ICON_RNA_ADD = BND_ICONID(25,22),

	BND_ICON_OUTLINER_OB_EMPTY = BND_ICONID(0,20),
	BND_ICON_OUTLINER_OB_MESH = BND_ICONID(1,20),
	BND_ICON_OUTLINER_OB_CURVE = BND_ICONID(2,20),
	BND_ICON_OUTLINER_OB_LATTICE = BND_ICONID(3,20),
	BND_ICON_OUTLINER_OB_META = BND_ICONID(4,20),
	BND_ICON_OUTLINER_OB_LAMP = BND_ICONID(5,20),
	BND_ICON_OUTLINER_OB_CAMERA = BND_ICONID(6,20),
	BND_ICON_OUTLINER_OB_ARMATURE = BND_ICONID(7,20),
	BND_ICON_OUTLINER_OB_FONT = BND_ICONID(8,20),
	BND_ICON_OUTLINER_OB_SURFACE = BND_ICONID(9,20),
	BND_ICON_OUTLINER_OB_SPEAKER = BND_ICONID(10,20),
	BND_ICON_RESTRICT_VIEW_OFF = BND_ICONID(19,20),
	BND_ICON_RESTRICT_VIEW_ON = BND_ICONID(20,20),
	BND_ICON_RESTRICT_SELECT_OFF = BND_ICONID(21,20),
	BND_ICON_RESTRICT_SELECT_ON = BND_ICONID(22,20),
	BND_ICON_RESTRICT_RENDER_OFF = BND_ICONID(23,20),
	BND_ICON_RESTRICT_RENDER_ON = BND_ICONID(24,20),

	BND_ICON_OUTLINER_DATA_EMPTY = BND_ICONID(0,19),
	BND_ICON_OUTLINER_DATA_MESH = BND_ICONID(1,19),
	BND_ICON_OUTLINER_DATA_CURVE = BND_ICONID(2,19),
	BND_ICON_OUTLINER_DATA_LATTICE = BND_ICONID(3,19),
	BND_ICON_OUTLINER_DATA_META = BND_ICONID(4,19),
	BND_ICON_OUTLINER_DATA_LAMP = BND_ICONID(5,19),
	BND_ICON_OUTLINER_DATA_CAMERA = BND_ICONID(6,19),
	BND_ICON_OUTLINER_DATA_ARMATURE = BND_ICONID(7,19),
	BND_ICON_OUTLINER_DATA_FONT = BND_ICONID(8,19),
	BND_ICON_OUTLINER_DATA_SURFACE = BND_ICONID(9,19),
	BND_ICON_OUTLINER_DATA_SPEAKER = BND_ICONID(10,19),
	BND_ICON_OUTLINER_DATA_POSE = BND_ICONID(11,19),

	BND_ICON_MESH_PLANE = BND_ICONID(0,18),
	BND_ICON_MESH_CUBE = BND_ICONID(1,18),
	BND_ICON_MESH_CIRCLE = BND_ICONID(2,18),
	BND_ICON_MESH_UVSPHERE = BND_ICONID(3,18),
	BND_ICON_MESH_ICOSPHERE = BND_ICONID(4,18),
	BND_ICON_MESH_GRID = BND_ICONID(5,18),
	BND_ICON_MESH_MONKEY = BND_ICONID(6,18),
	BND_ICON_MESH_CYLINDER = BND_ICONID(7,18),
	BND_ICON_MESH_TORUS = BND_ICONID(8,18),
	BND_ICON_MESH_CONE = BND_ICONID(9,18),
	BND_ICON_LAMP_POINT = BND_ICONID(12,18),
	BND_ICON_LAMP_SUN = BND_ICONID(13,18),
	BND_ICON_LAMP_SPOT = BND_ICONID(14,18),
	BND_ICON_LAMP_HEMI = BND_ICONID(15,18),
	BND_ICON_LAMP_AREA = BND_ICONID(16,18),
	BND_ICON_META_EMPTY = BND_ICONID(19,18),
	BND_ICON_META_PLANE = BND_ICONID(20,18),
	BND_ICON_META_CUBE = BND_ICONID(21,18),
	BND_ICON_META_BALL = BND_ICONID(22,18),
	BND_ICON_META_ELLIPSOID = BND_ICONID(23,18),
	BND_ICON_META_CAPSULE = BND_ICONID(24,18),

	BND_ICON_SURFACE_NCURVE = BND_ICONID(0,17),
	BND_ICON_SURFACE_NCIRCLE = BND_ICONID(1,17),
	BND_ICON_SURFACE_NSURFACE = BND_ICONID(2,17),
	BND_ICON_SURFACE_NCYLINDER = BND_ICONID(3,17),
	BND_ICON_SURFACE_NSPHERE = BND_ICONID(4,17),
	BND_ICON_SURFACE_NTORUS = BND_ICONID(5,17),
	BND_ICON_CURVE_BEZCURVE = BND_ICONID(9,17),
	BND_ICON_CURVE_BEZCIRCLE = BND_ICONID(10,17),
	BND_ICON_CURVE_NCURVE = BND_ICONID(11,17),
	BND_ICON_CURVE_NCIRCLE = BND_ICONID(12,17),
	BND_ICON_CURVE_PATH = BND_ICONID(13,17),
	BND_ICON_COLOR_RED = BND_ICONID(19,17),
	BND_ICON_COLOR_GREEN = BND_ICONID(20,17),
	BND_ICON_COLOR_BLUE = BND_ICONID(21,17),

	BND_ICON_FORCE_FORCE = BND_ICONID(0,16),
	BND_ICON_FORCE_WIND = BND_ICONID(1,16),
	BND_ICON_FORCE_VORTEX = BND_ICONID(2,16),
	BND_ICON_FORCE_MAGNETIC = BND_ICONID(3,16),
	BND_ICON_FORCE_HARMONIC = BND_ICONID(4,16),
	BND_ICON_FORCE_CHARGE = BND_ICONID(5,16),
	BND_ICON_FORCE_LENNARDJONES = BND_ICONID(6,16),
	BND_ICON_FORCE_TEXTURE = BND_ICONID(7,16),
	BND_ICON_FORCE_CURVE = BND_ICONID(8,16),
	BND_ICON_FORCE_BOID = BND_ICONID(9,16),
	BND_ICON_FORCE_TURBULENCE = BND_ICONID(10,16),
	BND_ICON_FORCE_DRAG = BND_ICONID(11,16),
	BND_ICON_FORCE_SMOKEFLOW = BND_ICONID(12,16),

	BND_ICON_MODIFIER = BND_ICONID(0,12),
	BND_ICON_MOD_WAVE = BND_ICONID(1,12),
	BND_ICON_MOD_BUILD = BND_ICONID(2,12),
	BND_ICON_MOD_DECIM = BND_ICONID(3,12),
	BND_ICON_MOD_MIRROR = BND_ICONID(4,12),
	BND_ICON_MOD_SOFT = BND_ICONID(5,12),
	BND_ICON_MOD_SUBSURF = BND_ICONID(6,12),
	BND_ICON_HOOK = BND_ICONID(7,12),
	BND_ICON_MOD_PHYSICS = BND_ICONID(8,12),
	BND_ICON_MOD_PARTICLES = BND_ICONID(9,12),
	BND_ICON_MOD_BOOLEAN = BND_ICONID(10,12),
	BND_ICON_MOD_EDGESPLIT = BND_ICONID(11,12),
	BND_ICON_MOD_ARRAY = BND_ICONID(12,12),
	BND_ICON_MOD_UVPROJECT = BND_ICONID(13,12),
	BND_ICON_MOD_DISPLACE = BND_ICONID(14,12),
	BND_ICON_MOD_CURVE = BND_ICONID(15,12),
	BND_ICON_MOD_LATTICE = BND_ICONID(16,12),
	BND_ICON_CONSTRAINT_DATA = BND_ICONID(17,12),
	BND_ICON_MOD_ARMATURE = BND_ICONID(18,12),
	BND_ICON_MOD_SHRINKWRAP = BND_ICONID(19,12),
	BND_ICON_MOD_CAST = BND_ICONID(20,12),
	BND_ICON_MOD_MESHDEFORM = BND_ICONID(21,12),
	BND_ICON_MOD_BEVEL = BND_ICONID(22,12),
	BND_ICON_MOD_SMOOTH = BND_ICONID(23,12),
	BND_ICON_MOD_SIMPLEDEFORM = BND_ICONID(24,12),
	BND_ICON_MOD_MASK = BND_ICONID(25,12),

	BND_ICON_MOD_CLOTH = BND_ICONID(0,11),
	BND_ICON_MOD_EXPLODE = BND_ICONID(1,11),
	BND_ICON_MOD_FLUIDSIM = BND_ICONID(2,11),
	BND_ICON_MOD_MULTIRES = BND_ICONID(3,11),
	BND_ICON_MOD_SMOKE = BND_ICONID(4,11),
	BND_ICON_MOD_SOLIDIFY = BND_ICONID(5,11),
	BND_ICON_MOD_SCREW = BND_ICONID(6,11),
	BND_ICON_MOD_VERTEX_WEIGHT = BND_ICONID(7,11),
	BND_ICON_MOD_DYNAMICPAINT = BND_ICONID(8,11),
	BND_ICON_MOD_REMESH = BND_ICONID(9,11),
	BND_ICON_MOD_OCEAN = BND_ICONID(10,11),
	BND_ICON_MOD_WARP = BND_ICONID(11,11),
	BND_ICON_MOD_SKIN = BND_ICONID(12,11),
	BND_ICON_MOD_TRIANGULATE = BND_ICONID(13,11),
	BND_ICON_MOD_WIREFRAME = BND_ICONID(14,11),

	BND_ICON_REC = BND_ICONID(0,10),
	BND_ICON_PLAY = BND_ICONID(1,10),
	BND_ICON_FF = BND_ICONID(2,10),
	BND_ICON_REW = BND_ICONID(3,10),
	BND_ICON_PAUSE = BND_ICONID(4,10),
	BND_ICON_PREV_KEYFRAME = BND_ICONID(5,10),
	BND_ICON_NEXT_KEYFRAME = BND_ICONID(6,10),
	BND_ICON_PLAY_AUDIO = BND_ICONID(7,10),
	BND_ICON_PLAY_REVERSE = BND_ICONID(8,10),
	BND_ICON_PREVIEW_RANGE = BND_ICONID(9,10),
	BND_ICON_ACTION_TWEAK = BND_ICONID(10,10),
	BND_ICON_PMARKER_ACT = BND_ICONID(11,10),
	BND_ICON_PMARKER_SEL = BND_ICONID(12,10),
	BND_ICON_PMARKER = BND_ICONID(13,10),
	BND_ICON_MARKER_HLT = BND_ICONID(14,10),
	BND_ICON_MARKER = BND_ICONID(15,10),
	BND_ICON_SPACE2 = BND_ICONID(16,10),
	BND_ICON_SPACE3 = BND_ICONID(17,10),
	BND_ICON_KEYINGSET = BND_ICONID(18,10),
	BND_ICON_KEY_DEHLT = BND_ICONID(19,10),
	BND_ICON_KEY_HLT = BND_ICONID(20,10),
	BND_ICON_MUTE_IPO_OFF = BND_ICONID(21,10),
	BND_ICON_MUTE_IPO_ON = BND_ICONID(22,10),
	BND_ICON_VISIBLE_IPO_OFF = BND_ICONID(23,10),
	BND_ICON_VISIBLE_IPO_ON = BND_ICONID(24,10),
	BND_ICON_DRIVER = BND_ICONID(25,10),

	BND_ICON_SOLO_OFF = BND_ICONID(0,9),
	BND_ICON_SOLO_ON = BND_ICONID(1,9),
	BND_ICON_FRAME_PREV = BND_ICONID(2,9),
	BND_ICON_FRAME_NEXT = BND_ICONID(3,9),
	BND_ICON_NLA_PUSHDOWN = BND_ICONID(4,9),
	BND_ICON_IPO_CONSTANT = BND_ICONID(5,9),
	BND_ICON_IPO_LINEAR = BND_ICONID(6,9),
	BND_ICON_IPO_BEZIER = BND_ICONID(7,9),
	BND_ICON_IPO_SINE = BND_ICONID(8,9),
	BND_ICON_IPO_QUAD = BND_ICONID(9,9),
	BND_ICON_IPO_CUBIC = BND_ICONID(10,9),
	BND_ICON_IPO_QUART = BND_ICONID(11,9),
	BND_ICON_IPO_QUINT = BND_ICONID(12,9),
	BND_ICON_IPO_EXPO = BND_ICONID(13,9),
	BND_ICON_IPO_CIRC = BND_ICONID(14,9),
	BND_ICON_IPO_BOUNCE = BND_ICONID(15,9),
	BND_ICON_IPO_ELASTIC = BND_ICONID(16,9),
	BND_ICON_IPO_BACK = BND_ICONID(17,9),
	BND_ICON_IPO_EASE_IN = BND_ICONID(18,9),
	BND_ICON_IPO_EASE_OUT = BND_ICONID(19,9),
	BND_ICON_IPO_EASE_IN_OUT = BND_ICONID(20,9),

	BND_ICON_VERTEXSEL = BND_ICONID(0,8),
	BND_ICON_EDGESEL = BND_ICONID(1,8),
	BND_ICON_FACESEL = BND_ICONID(2,8),
	BND_ICON_LOOPSEL = BND_ICONID(3,8),
	BND_ICON_ROTATE = BND_ICONID(5,8),
	BND_ICON_CURSOR = BND_ICONID(6,8),
	BND_ICON_ROTATECOLLECTION = BND_ICONID(7,8),
	BND_ICON_ROTATECENTER = BND_ICONID(8,8),
	BND_ICON_ROTACTIVE = BND_ICONID(9,8),
	BND_ICON_ALIGN = BND_ICONID(10,8),
	BND_ICON_SMOOTHCURVE = BND_ICONID(12,8),
	BND_ICON_SPHERECURVE = BND_ICONID(13,8),
	BND_ICON_ROOTCURVE = BND_ICONID(14,8),
	BND_ICON_SHARPCURVE = BND_ICONID(15,8),
	BND_ICON_LINCURVE = BND_ICONID(16,8),
	BND_ICON_NOCURVE = BND_ICONID(17,8),
	BND_ICON_RNDCURVE = BND_ICONID(18,8),
	BND_ICON_PROP_OFF = BND_ICONID(19,8),
	BND_ICON_PROP_ON = BND_ICONID(20,8),
	BND_ICON_PROP_CON = BND_ICONID(21,8),
	BND_ICON_SCULPT_DYNTOPO = BND_ICONID(22,8),
	BND_ICON_PARTICLE_POINT = BND_ICONID(23,8),
	BND_ICON_PARTICLE_TIP = BND_ICONID(24,8),
	BND_ICON_PARTICLE_PATH = BND_ICONID(25,8),

	BND_ICON_MAN_TRANS = BND_ICONID(0,7),
	BND_ICON_MAN_ROT = BND_ICONID(1,7),
	BND_ICON_MAN_SCALE = BND_ICONID(2,7),
	BND_ICON_MANIPUL = BND_ICONID(3,7),
	BND_ICON_SNAP_OFF = BND_ICONID(4,7),
	BND_ICON_SNAP_ON = BND_ICONID(5,7),
	BND_ICON_SNAP_NORMAL = BND_ICONID(6,7),
	BND_ICON_SNAP_INCREMENT = BND_ICONID(7,7),
	BND_ICON_SNAP_VERTEX = BND_ICONID(8,7),
	BND_ICON_SNAP_EDGE = BND_ICONID(9,7),
	BND_ICON_SNAP_FACE = BND_ICONID(10,7),
	BND_ICON_SNAP_VOLUME = BND_ICONID(11,7),
	BND_ICON_STICKY_UVS_LOC = BND_ICONID(13,7),
	BND_ICON_STICKY_UVS_DISABLE = BND_ICONID(14,7),
	BND_ICON_STICKY_UVS_VERT = BND_ICONID(15,7),
	BND_ICON_CLIPUV_DEHLT = BND_ICONID(16,7),
	BND_ICON_CLIPUV_HLT = BND_ICONID(17,7),
	BND_ICON_SNAP_PEEL_OBJECT = BND_ICONID(18,7),
	BND_ICON_GRID = BND_ICONID(19,7),

	BND_ICON_PASTEDOWN = BND_ICONID(0,6),
	BND_ICON_COPYDOWN = BND_ICONID(1,6),
	BND_ICON_PASTEFLIPUP = BND_ICONID(2,6),
	BND_ICON_PASTEFLIPDOWN = BND_ICONID(3,6),
	BND_ICON_SNAP_SURFACE = BND_ICONID(8,6),
	BND_ICON_AUTOMERGE_ON = BND_ICONID(9,6),
	BND_ICON_AUTOMERGE_OFF = BND_ICONID(10,6),
	BND_ICON_RETOPO = BND_ICONID(11,6),
	BND_ICON_UV_VERTEXSEL = BND_ICONID(12,6),
	BND_ICON_UV_EDGESEL = BND_ICONID(13,6),
	BND_ICON_UV_FACESEL = BND_ICONID(14,6),
	BND_ICON_UV_ISLANDSEL = BND_ICONID(15,6),
	BND_ICON_UV_SYNC_SELECT = BND_ICONID(16,6),

	BND_ICON_BBOX = BND_ICONID(0,5),
	BND_ICON_WIRE = BND_ICONID(1,5),
	BND_ICON_SOLID = BND_ICONID(2,5),
	BND_ICON_SMOOTH = BND_ICONID(3,5),
	BND_ICON_POTATO = BND_ICONID(4,5),
	BND_ICON_ORTHO = BND_ICONID(6,5),
	BND_ICON_LOCKVIEW_OFF = BND_ICONID(9,5),
	BND_ICON_LOCKVIEW_ON = BND_ICONID(10,5),
	BND_ICON_AXIS_SIDE = BND_ICONID(12,5),
	BND_ICON_AXIS_FRONT = BND_ICONID(13,5),
	BND_ICON_AXIS_TOP = BND_ICONID(14,5),
	BND_ICON_NDOF_DOM = BND_ICONID(15,5),
	BND_ICON_NDOF_TURN = BND_ICONID(16,5),
	BND_ICON_NDOF_FLY = BND_ICONID(17,5),
	BND_ICON_NDOF_TRANS = BND_ICONID(18,5),
	BND_ICON_LAYER_USED = BND_ICONID(19,5),
	BND_ICON_LAYER_ACTIVE = BND_ICONID(20,5),

	BND_ICON_SORTALPHA = BND_ICONID(0,3),
	BND_ICON_SORTBYEXT = BND_ICONID(1,3),
	BND_ICON_SORTTIME = BND_ICONID(2,3),
	BND_ICON_SORTSIZE = BND_ICONID(3,3),
	BND_ICON_LONGDISPLAY = BND_ICONID(4,3),
	BND_ICON_SHORTDISPLAY = BND_ICONID(5,3),
	BND_ICON_GHOST = BND_ICONID(6,3),
	BND_ICON_IMGDISPLAY = BND_ICONID(7,3),
	BND_ICON_SAVE_AS = BND_ICONID(8,3),
	BND_ICON_SAVE_COPY = BND_ICONID(9,3),
	BND_ICON_BOOKMARKS = BND_ICONID(10,3),
	BND_ICON_FONTPREVIEW = BND_ICONID(11,3),
	BND_ICON_FILTER = BND_ICONID(12,3),
	BND_ICON_NEWFOLDER = BND_ICONID(13,3),
	BND_ICON_OPEN_RECENT = BND_ICONID(14,3),
	BND_ICON_FILE_PARENT = BND_ICONID(15,3),
	BND_ICON_FILE_REFRESH = BND_ICONID(16,3),
	BND_ICON_FILE_FOLDER = BND_ICONID(17,3),
	BND_ICON_FILE_BLANK = BND_ICONID(18,3),
	BND_ICON_FILE_BLEND = BND_ICONID(19,3),
	BND_ICON_FILE_IMAGE = BND_ICONID(20,3),
	BND_ICON_FILE_MOVIE = BND_ICONID(21,3),
	BND_ICON_FILE_SCRIPT = BND_ICONID(22,3),
	BND_ICON_FILE_SOUND = BND_ICONID(23,3),
	BND_ICON_FILE_FONT = BND_ICONID(24,3),
	BND_ICON_FILE_TEXT = BND_ICONID(25,3),

	BND_ICON_RECOVER_AUTO = BND_ICONID(0,2),
	BND_ICON_SAVE_PREFS = BND_ICONID(1,2),
	BND_ICON_LINK_BLEND = BND_ICONID(2,2),
	BND_ICON_APPEND_BLEND = BND_ICONID(3,2),
	BND_ICON_IMPORT = BND_ICONID(4,2),
	BND_ICON_EXPORT = BND_ICONID(5,2),
	BND_ICON_EXTERNAL_DATA = BND_ICONID(6,2),
	BND_ICON_LOAD_FACTORY = BND_ICONID(7,2),
	BND_ICON_LOOP_BACK = BND_ICONID(13,2),
	BND_ICON_LOOP_FORWARDS = BND_ICONID(14,2),
	BND_ICON_BACK = BND_ICONID(15,2),
	BND_ICON_FORWARD = BND_ICONID(16,2),
	BND_ICON_FILE_BACKUP = BND_ICONID(24,2),
	BND_ICON_DISK_DRIVE = BND_ICONID(25,2),

	BND_ICON_MATPLANE = BND_ICONID(0,1),
	BND_ICON_MATSPHERE = BND_ICONID(1,1),
	BND_ICON_MATCUBE = BND_ICONID(2,1),
	BND_ICON_MONKEY = BND_ICONID(3,1),
	BND_ICON_HAIR = BND_ICONID(4,1),
	BND_ICON_ALIASED = BND_ICONID(5,1),
	BND_ICON_ANTIALIASED = BND_ICONID(6,1),
	BND_ICON_MAT_SPHERE_SKY = BND_ICONID(7,1),
	BND_ICON_WORDWRAP_OFF = BND_ICONID(12,1),
	BND_ICON_WORDWRAP_ON = BND_ICONID(13,1),
	BND_ICON_SYNTAX_OFF = BND_ICONID(14,1),
	BND_ICON_SYNTAX_ON = BND_ICONID(15,1),
	BND_ICON_LINENUMBERS_OFF = BND_ICONID(16,1),
	BND_ICON_LINENUMBERS_ON = BND_ICONID(17,1),
	BND_ICON_SCRIPTPLUGINS = BND_ICONID(18,1),

	BND_ICON_SEQ_SEQUENCER = BND_ICONID(0,0),
	BND_ICON_SEQ_PREVIEW = BND_ICONID(1,0),
	BND_ICON_SEQ_LUMA_WAVEFORM = BND_ICONID(2,0),
	BND_ICON_SEQ_CHROMA_SCOPE = BND_ICONID(3,0),
	BND_ICON_SEQ_HISTOGRAM = BND_ICONID(4,0),
	BND_ICON_SEQ_SPLITVIEW = BND_ICONID(5,0),
	BND_ICON_IMAGE_RGB = BND_ICONID(9,0),
	BND_ICON_IMAGE_RGB_ALPHA = BND_ICONID(10,0),
	BND_ICON_IMAGE_ALPHA = BND_ICONID(11,0),
	BND_ICON_IMAGE_ZDEPTH = BND_ICONID(12,0),
	BND_ICON_IMAGEFILE = BND_ICONID(13,0),
}

float bnd_fminf(float a, float b) {
    return fmin(a, b);
}

float bnd_fmaxf(float a, float b) {
    return fmax(a, b);
}

double bnd_fmin(double a, double b) {
    return fmin(a, b);
}

double bnd_fmax(double a, double b) {
    return fmax(a, b);
}

////////////////////////////////////////////////////////////////////////////////

// default text size
enum BND_LABEL_FONT_SIZE = 13;

// default text padding in inner box
enum BND_PAD_LEFT = 8;
enum BND_PAD_RIGHT = 8;

// label: value separator string
enum BND_LABEL_SEPARATOR = ": ";

// alpha intensity of transparent items (0xa4)
enum BND_TRANSPARENT_ALPHA = 0.643;

// shade intensity of beveled panels
enum BND_BEVEL_SHADE = 30;
// shade intensity of beveled insets
enum BND_INSET_BEVEL_SHADE = 30;
// shade intensity of hovered inner boxes
enum BND_HOVER_SHADE = 15;
// shade intensity of splitter bevels
enum BND_SPLITTER_SHADE = 100;

// width of icon sheet
enum BND_ICON_SHEET_WIDTH = 602;
// height of icon sheet
enum BND_ICON_SHEET_HEIGHT = 640;
// gridsize of icon sheet in both dimensions
enum BND_ICON_SHEET_GRID = 21;
// offset of first icon tile relative to left border
enum BND_ICON_SHEET_OFFSET_X = 5;
// offset of first icon tile relative to top border
enum BND_ICON_SHEET_OFFSET_Y = 10;
// resolution of single icon
enum BND_ICON_SHEET_RES = 16;

// size of number field arrow
enum BND_NUMBER_ARROW_SIZE = 4;

// default text color
enum BND_COLOR_TEXT = NVGcolor(0,0,0,1);
// default highlighted text color
enum BND_COLOR_TEXT_SELECTED = NVGcolor(1,1,1,1);

// radius of tool button
enum BND_TOOL_RADIUS = 4;

// radius of option button
enum BND_OPTION_RADIUS = 4;
// width of option button checkbox
enum BND_OPTION_WIDTH = 14;
// height of option button checkbox
enum BND_OPTION_HEIGHT = 15;

// radius of text field
enum BND_TEXT_RADIUS = 4;

// radius of number button
enum BND_NUMBER_RADIUS = 10;

// radius of menu popup
enum BND_MENU_RADIUS = 3;
// feather of menu popup shadow
enum BND_SHADOW_FEATHER = 12;
// alpha of menu popup shadow
enum BND_SHADOW_ALPHA = 0.5;

// radius of scrollbar
enum BND_SCROLLBAR_RADIUS = 7;
// shade intensity of active scrollbar
enum BND_SCROLLBAR_ACTIVE_SHADE = 15;

// max glyphs for position testing
enum BND_MAX_GLYPHS = 1024;

// max rows for position testing
enum BND_MAX_ROWS = 32;

// text distance from bottom
enum BND_TEXT_PAD_DOWN = 7;

// stroke width of wire outline
enum BND_NODE_WIRE_OUTLINE_WIDTH = 4;
// stroke width of wire
enum BND_NODE_WIRE_WIDTH = 2;
// radius of node box
enum BND_NODE_RADIUS = 8;
// feather of node title text
enum BND_NODE_TITLE_FEATHER = 1;
// size of node title arrow
enum BND_NODE_ARROW_SIZE = 9;

////////////////////////////////////////////////////////////////////////////////

float bnd_clamp(float v, float mn, float mx) {
    return (v > mx)?mx:(v < mn)?mn:v;
}

////////////////////////////////////////////////////////////////////////////////

// the initial theme
static BNDtheme bnd_theme = BNDtheme(
    // backgroundColor
    NVGcolor(0.447, 0.447, 0.447, 1.0),
    // regularTheme
    BNDwidgetTheme(
        NVGcolor(0.098,0.098,0.098,1), // color_outline
        NVGcolor(0.098,0.098,0.098,1), // color_item
        NVGcolor(0.6,0.6,0.6,1), // color_inner
        NVGcolor(0.392,0.392,0.392,1), // color_inner_selected
        BND_COLOR_TEXT, // color_text
        BND_COLOR_TEXT_SELECTED, // color_text_selected        
        0, // shade_top
        0, // shade_down
    ),    
    // toolTheme
    BNDwidgetTheme(
        NVGcolor(0.098,0.098,0.098,1), // color_outline
        NVGcolor(0.098,0.098,0.098,1), // color_item
        NVGcolor(0.6,0.6,0.6,1), // color_inner
        NVGcolor(0.392,0.392,0.392,1), // color_inner_selected
        BND_COLOR_TEXT, // color_text
        BND_COLOR_TEXT_SELECTED, // color_text_selected        
        15, // shade_top
        -15, // shade_down
    ),
    // radioTheme
    BNDwidgetTheme(
        NVGcolor(0,0,0,1), // color_outline
        NVGcolor(1,1,1,1), // color_item
        NVGcolor(0.275,0.275,0.275,1), // color_inner
        NVGcolor(0.337,0.502,0.761,1), // color_inner_selected
        BND_COLOR_TEXT_SELECTED, // color_text
        BND_COLOR_TEXT, // color_text_selected        
        15, // shade_top
        -15, // shade_down
    ),
    // textFieldTheme
    BNDwidgetTheme(
        NVGcolor(0.098,0.098,0.098,1), // color_outline
        NVGcolor(0.353, 0.353, 0.353,1), // color_item
        NVGcolor(0.6, 0.6, 0.6,1), // color_inner
        NVGcolor(0.6, 0.6, 0.6,1), // color_inner_selected
        BND_COLOR_TEXT, // color_text
        BND_COLOR_TEXT_SELECTED, // color_text_selected        
        0, // shade_top
        25, // shade_down
    ),
    // optionTheme
    BNDwidgetTheme(
        NVGcolor(0,0,0,1), // color_outline
        NVGcolor(1,1,1,1), // color_item
        NVGcolor(0.275,0.275,0.275,1), // color_inner
        NVGcolor(0.275,0.275,0.275,1), // color_inner_selected
        BND_COLOR_TEXT, // color_text
        BND_COLOR_TEXT_SELECTED, // color_text_selected        
        15, // shade_top
        -15, // shade_down
    ),
    // choiceTheme
    BNDwidgetTheme(
        NVGcolor(0,0,0,1), // color_outline
        NVGcolor(1,1,1,1), // color_item
        NVGcolor(0.275,0.275,0.275,1), // color_inner
        NVGcolor(0.275,0.275,0.275,1), // color_inner_selected
        BND_COLOR_TEXT_SELECTED, // color_text
        NVGcolor(0.8,0.8,0.8,1), // color_text_selected        
        15, // shade_top
        -15, // shade_down
    ),
    // numberFieldTheme
    BNDwidgetTheme(
        NVGcolor(0.098,0.098,0.098,1), // color_outline
        NVGcolor(0.353, 0.353, 0.353,1), // color_item
        NVGcolor(0.706, 0.706, 0.706,1), // color_inner
        NVGcolor(0.6, 0.6, 0.6,1), // color_inner_selected
        BND_COLOR_TEXT, // color_text
        BND_COLOR_TEXT_SELECTED, // color_text_selected        
        -20, // shade_top
        0, // shade_down
    ),
    // sliderTheme
    BNDwidgetTheme(
        NVGcolor(0.098,0.098,0.098,1), // color_outline
        NVGcolor(0.502,0.502,0.502,1), // color_item
        NVGcolor(0.706, 0.706, 0.706,1), // color_inner
        NVGcolor(0.6, 0.6, 0.6,1), // color_inner_selected
        BND_COLOR_TEXT, // color_text
        BND_COLOR_TEXT_SELECTED, // color_text_selected        
        -20, // shade_top
        0, // shade_down
    ),
    // scrollBarTheme
    BNDwidgetTheme(
        NVGcolor(0.196,0.196,0.196,1), // color_outline
        NVGcolor(0.502,0.502,0.502,1), // color_item
        NVGcolor(0.314, 0.314, 0.314,0.706), // color_inner
        NVGcolor(0.392, 0.392, 0.392,0.706), // color_inner_selected
        BND_COLOR_TEXT, // color_text
        BND_COLOR_TEXT_SELECTED, // color_text_selected        
        5, // shade_top
        -5, // shade_down
    ),
    // tooltipTheme
    BNDwidgetTheme(
        NVGcolor(0,0,0,1), // color_outline
        NVGcolor(0.392,0.392,0.392,1), // color_item
        NVGcolor(0.098, 0.098, 0.098, 0.902), // color_inner
        NVGcolor(0.176, 0.176, 0.176, 0.902), // color_inner_selected
        NVGcolor(0.627, 0.627, 0.627, 1), // color_text
        BND_COLOR_TEXT_SELECTED, // color_text_selected        
        0, // shade_top
        0, // shade_down
    ),
    // menuTheme
    BNDwidgetTheme(
        NVGcolor(0,0,0,1), // color_outline
        NVGcolor(0.392,0.392,0.392,1), // color_item
        NVGcolor(0.098, 0.098, 0.098, 0.902), // color_inner
        NVGcolor(0.176, 0.176, 0.176, 0.902), // color_inner_selected
        NVGcolor(0.627, 0.627, 0.627, 1), // color_text
        BND_COLOR_TEXT_SELECTED, // color_text_selected        
        0, // shade_top
        0, // shade_down
    ),
    // menuItemTheme
    BNDwidgetTheme(
        NVGcolor(0,0,0,1), // color_outline
        NVGcolor(0.675,0.675,0.675,0.502), // color_item
        NVGcolor(0,0,0,0), // color_inner
        NVGcolor(0.337,0.502,0.761,1), // color_inner_selected
        BND_COLOR_TEXT_SELECTED, // color_text
        BND_COLOR_TEXT, // color_text_selected        
        38, // shade_top
        0, // shade_down
    ),
    // nodeTheme
    BNDnodeTheme(
        NVGcolor(0.945,0.345,0,1), // nodeSelectedColor
        NVGcolor(0,0,0,1), // wiresColor
        NVGcolor(0.498,0.439,0.439,1), // textSelectedColor
        NVGcolor(1,0.667,0.251,1), // activeNodeColor
        NVGcolor(1,1,1,1), // wireSelectColor
        NVGcolor(0.608,0.608,0.608,0.627), // nodeBackdropColor
        5, // noodleCurving
    ),
);

////////////////////////////////////////////////////////////////////////////////

void bndSetTheme(BNDtheme theme) {
    bnd_theme = theme;
}

const(BNDtheme)* bndGetTheme() {
    return &bnd_theme;
}

// the handle to the image containing the icon sheet
static int bnd_icon_image = -1;

void bndSetIconImage(int image) {
    bnd_icon_image = image;
}

// the handle to the UI font
static int bnd_font = -1;

void bndSetFont(int font) {
    bnd_font = font;
}

////////////////////////////////////////////////////////////////////////////////

void bndLabel(NVGcontext* ctx, float x, float y, float w, float h, int iconid, const(char)* label) {
    bndIconLabelValue(ctx,x,y,w,h,iconid,
        bnd_theme.regularTheme.textColor, BNDtextAlignment.BND_LEFT,
        BND_LABEL_FONT_SIZE, label, null);
}

void bndToolButton(NVGcontext* ctx, float x, float y, float w, float h, int flags, BNDwidgetState state, int iconid, const(char)* label) {
    float[4] cr;
    NVGcolor shade_top, shade_down;
    
    bndSelectCorners(cr.ptr, BND_TOOL_RADIUS, flags);
    bndBevelInset(ctx,x,y,w,h,cr[2],cr[3]);    
    bndInnerColors(&shade_top, &shade_down, &bnd_theme.toolTheme, state, 1);
    bndInnerBox(ctx,x,y,w,h,cr[0],cr[1],cr[2],cr[3], shade_top, shade_down);
    bndOutlineBox(ctx,x,y,w,h,cr[0],cr[1],cr[2],cr[3],
        bndTransparent(bnd_theme.toolTheme.outlineColor));
    bndIconLabelValue(ctx,x,y,w,h,iconid,
        bndTextColor(&bnd_theme.toolTheme, state), BNDtextAlignment.BND_CENTER,
        BND_LABEL_FONT_SIZE, label, null);
}

void bndRadioButton(NVGcontext* ctx, float x, float y, float w, float h, int flags, BNDwidgetState state, int iconid, const(char)* label) {
    float[4] cr;
    NVGcolor shade_top, shade_down;
    
    bndSelectCorners(cr.ptr, BND_OPTION_RADIUS, flags);
    bndBevelInset(ctx,x,y,w,h,cr[2],cr[3]);    
    bndInnerColors(&shade_top, &shade_down, &bnd_theme.radioTheme, state, 1);
    bndInnerBox(ctx,x,y,w,h,cr[0],cr[1],cr[2],cr[3], shade_top, shade_down);
    bndOutlineBox(ctx,x,y,w,h,cr[0],cr[1],cr[2],cr[3],
        bndTransparent(bnd_theme.radioTheme.outlineColor));
    bndIconLabelValue(ctx,x,y,w,h,iconid,
        bndTextColor(&bnd_theme.radioTheme, state), BNDtextAlignment.BND_CENTER,
        BND_LABEL_FONT_SIZE, label, null);
}

int bndTextFieldTextPosition(NVGcontext* ctx, float x, float y, float w, float h, int iconid, const(char)* text, int px, int py) {
    return bndIconLabelTextPosition(ctx, x, y, w, h, iconid, BND_LABEL_FONT_SIZE, text, px, py);
}

void bndTextField(NVGcontext* ctx,  float x, float y, float w, float h, int flags, BNDwidgetState state, int iconid, const(char)* text, int cbegin, int cend) {
    float[4] cr;
    NVGcolor shade_top, shade_down;
    
    bndSelectCorners(cr.ptr, BND_TEXT_RADIUS, flags);
    bndBevelInset(ctx,x,y,w,h,cr[2],cr[3]);    
    bndInnerColors(&shade_top, &shade_down, &bnd_theme.textFieldTheme, state, 0);
    bndInnerBox(ctx,x,y,w,h,cr[0],cr[1],cr[2],cr[3], shade_top, shade_down);
    bndOutlineBox(ctx,x,y,w,h,cr[0],cr[1],cr[2],cr[3],
        bndTransparent(bnd_theme.textFieldTheme.outlineColor));
    if (state != BNDwidgetState.BND_ACTIVE) {
        cend = -1;
    }
    bndIconLabelCaret(ctx,x,y,w,h,iconid,
        bndTextColor(&bnd_theme.textFieldTheme, state), BND_LABEL_FONT_SIZE, 
        text, bnd_theme.textFieldTheme.itemColor, cbegin, cend);
}

void bndOptionButton(NVGcontext* ctx, float x, float y, float w, float h, BNDwidgetState state, const(char)* label) {
    float ox, oy;
    NVGcolor shade_top, shade_down;
    
    ox = x;
    oy = y+h-BND_OPTION_HEIGHT-3;
    
    bndBevelInset(ctx,ox,oy,
        BND_OPTION_WIDTH,BND_OPTION_HEIGHT,
        BND_OPTION_RADIUS,BND_OPTION_RADIUS);
    bndInnerColors(&shade_top, &shade_down, &bnd_theme.optionTheme, state, 1);
    bndInnerBox(ctx,ox,oy,
        BND_OPTION_WIDTH,BND_OPTION_HEIGHT,
        BND_OPTION_RADIUS,BND_OPTION_RADIUS,BND_OPTION_RADIUS,BND_OPTION_RADIUS,
        shade_top, shade_down);
    bndOutlineBox(ctx,ox,oy,
        BND_OPTION_WIDTH,BND_OPTION_HEIGHT,
        BND_OPTION_RADIUS,BND_OPTION_RADIUS,BND_OPTION_RADIUS,BND_OPTION_RADIUS,
        bndTransparent(bnd_theme.optionTheme.outlineColor));
    if (state == BNDwidgetState.BND_ACTIVE) {
        bndCheck(ctx,ox,oy, bndTransparent(bnd_theme.optionTheme.itemColor));
    }
    bndIconLabelValue(ctx,x+12,y,w-12,h,-1,
        bndTextColor(&bnd_theme.optionTheme, state), BNDtextAlignment.BND_LEFT,
        BND_LABEL_FONT_SIZE, label, null);
}

void bndChoiceButton(NVGcontext* ctx, float x, float y, float w, float h, int flags, BNDwidgetState state, int iconid, const(char)* label) {
    float[4] cr;
    NVGcolor shade_top, shade_down;
    
    bndSelectCorners(cr.ptr, BND_OPTION_RADIUS, flags);
    bndBevelInset(ctx,x,y,w,h,cr[2],cr[3]);    
    bndInnerColors(&shade_top, &shade_down, &bnd_theme.choiceTheme, state, 1);
    bndInnerBox(ctx,x,y,w,h,cr[0],cr[1],cr[2],cr[3], shade_top, shade_down);
    bndOutlineBox(ctx,x,y,w,h,cr[0],cr[1],cr[2],cr[3],
        bndTransparent(bnd_theme.choiceTheme.outlineColor));
    bndIconLabelValue(ctx,x,y,w,h,iconid,
        bndTextColor(&bnd_theme.choiceTheme, state), BNDtextAlignment.BND_LEFT,
        BND_LABEL_FONT_SIZE, label, null);
    bndUpDownArrow(ctx,x+w-10,y+10,5,
        bndTransparent(bnd_theme.choiceTheme.itemColor));
}

void bndColorButton(NVGcontext* ctx, float x, float y, float w, float h, int flags, NVGcolor color) {
    float[4] cr;
    bndSelectCorners(cr.ptr, BND_TOOL_RADIUS, flags);
    bndBevelInset(ctx,x,y,w,h,cr[2],cr[3]);
    bndInnerBox(ctx,x,y,w,h,cr[0],cr[1],cr[2],cr[3], color, color);
    bndOutlineBox(ctx,x,y,w,h,cr[0],cr[1],cr[2],cr[3],
        bndTransparent(bnd_theme.toolTheme.outlineColor));
}

void bndNumberField(NVGcontext* ctx, float x, float y, float w, float h, int flags, BNDwidgetState state, const(char)* label, const(char)* value) {
    float[4] cr;
    NVGcolor shade_top, shade_down;
    
    bndSelectCorners(cr.ptr, BND_NUMBER_RADIUS, flags);
    bndBevelInset(ctx,x,y,w,h,cr[2],cr[3]);    
    bndInnerColors(&shade_top, &shade_down, &bnd_theme.numberFieldTheme, state, 0);
    bndInnerBox(ctx,x,y,w,h,cr[0],cr[1],cr[2],cr[3], shade_top, shade_down);
    bndOutlineBox(ctx,x,y,w,h,cr[0],cr[1],cr[2],cr[3],
        bndTransparent(bnd_theme.numberFieldTheme.outlineColor));
    bndIconLabelValue(ctx,x,y,w,h,-1,
        bndTextColor(&bnd_theme.numberFieldTheme, state), BNDtextAlignment.BND_CENTER,
        BND_LABEL_FONT_SIZE, label, value);
    bndArrow(ctx,x+8,y+10,-BND_NUMBER_ARROW_SIZE,
        bndTransparent(bnd_theme.numberFieldTheme.itemColor));
    bndArrow(ctx,x+w-8,y+10,BND_NUMBER_ARROW_SIZE,
        bndTransparent(bnd_theme.numberFieldTheme.itemColor));
}

void bndSlider(NVGcontext* ctx, float x, float y, float w, float h, int flags, BNDwidgetState state, float progress, const(char)* label, const(char)* value) {
    float[4] cr;
    NVGcolor shade_top, shade_down;
    
    bndSelectCorners(cr.ptr, BND_NUMBER_RADIUS, flags);
    bndBevelInset(ctx,x,y,w,h,cr[2],cr[3]);
    bndInnerColors(&shade_top, &shade_down, &bnd_theme.sliderTheme, state, 0);
    bndInnerBox(ctx,x,y,w,h,cr[0],cr[1],cr[2],cr[3], shade_top, shade_down);

    if (state == BNDwidgetState.BND_ACTIVE) {
        shade_top = bndOffsetColor(
            bnd_theme.sliderTheme.itemColor, bnd_theme.sliderTheme.shadeTop);
        shade_down = bndOffsetColor(
            bnd_theme.sliderTheme.itemColor, bnd_theme.sliderTheme.shadeDown);
    } else {
        shade_top = bndOffsetColor(
            bnd_theme.sliderTheme.itemColor, bnd_theme.sliderTheme.shadeDown);
        shade_down = bndOffsetColor(
            bnd_theme.sliderTheme.itemColor, bnd_theme.sliderTheme.shadeTop);
    }    
    nvgScissor(ctx,x,y,8+(w-8)*bnd_clamp(progress,0,1),h);
    bndInnerBox(ctx,x,y,w,h,cr[0],cr[1],cr[2],cr[3], shade_top, shade_down);
    nvgResetScissor(ctx);
    
    bndOutlineBox(ctx,x,y,w,h,cr[0],cr[1],cr[2],cr[3],
        bndTransparent(bnd_theme.sliderTheme.outlineColor));
    bndIconLabelValue(ctx,x,y,w,h,-1,
        bndTextColor(&bnd_theme.sliderTheme, state), BNDtextAlignment.BND_CENTER,
        BND_LABEL_FONT_SIZE, label, value);
}

void bndScrollBar(NVGcontext* ctx, float x, float y, float w, float h, BNDwidgetState state, float offset, float size) {
    
    bndBevelInset(ctx,x,y,w,h,
        BND_SCROLLBAR_RADIUS, BND_SCROLLBAR_RADIUS);
    bndInnerBox(ctx,x,y,w,h,
        BND_SCROLLBAR_RADIUS,BND_SCROLLBAR_RADIUS,
        BND_SCROLLBAR_RADIUS,BND_SCROLLBAR_RADIUS,
        bndOffsetColor(
            bnd_theme.scrollBarTheme.innerColor, 3*bnd_theme.scrollBarTheme.shadeDown),
        bndOffsetColor(
            bnd_theme.scrollBarTheme.innerColor, 3*bnd_theme.scrollBarTheme.shadeTop));
    bndOutlineBox(ctx,x,y,w,h,
        BND_SCROLLBAR_RADIUS,BND_SCROLLBAR_RADIUS,
        BND_SCROLLBAR_RADIUS,BND_SCROLLBAR_RADIUS,
        bndTransparent(bnd_theme.scrollBarTheme.outlineColor));
    
    NVGcolor itemColor = bndOffsetColor(
        bnd_theme.scrollBarTheme.itemColor,
        (state == BNDwidgetState.BND_ACTIVE)?BND_SCROLLBAR_ACTIVE_SHADE:0);

    bndScrollHandleRect(&x,&y,&w,&h,offset,size);
    
    bndInnerBox(ctx,x,y,w,h,
        BND_SCROLLBAR_RADIUS,BND_SCROLLBAR_RADIUS,
        BND_SCROLLBAR_RADIUS,BND_SCROLLBAR_RADIUS,
        bndOffsetColor(
            itemColor, 3*bnd_theme.scrollBarTheme.shadeTop), 
        bndOffsetColor(
            itemColor, 3*bnd_theme.scrollBarTheme.shadeDown));
    bndOutlineBox(ctx,x,y,w,h,
        BND_SCROLLBAR_RADIUS,BND_SCROLLBAR_RADIUS,
        BND_SCROLLBAR_RADIUS,BND_SCROLLBAR_RADIUS,
        bndTransparent(bnd_theme.scrollBarTheme.outlineColor));
}

void bndMenuBackground(NVGcontext* ctx, float x, float y, float w, float h, int flags) {
    float[4] cr;
    NVGcolor shade_top, shade_down;
    
    bndSelectCorners(cr.ptr, BND_MENU_RADIUS, flags);
    bndInnerColors(&shade_top, &shade_down, &bnd_theme.menuTheme,
        BNDwidgetState.BND_DEFAULT, 0);
    bndInnerBox(ctx,x,y,w,h+1,cr[0],cr[1],cr[2],cr[3], shade_top, shade_down);
    bndOutlineBox(ctx,x,y,w,h+1,cr[0],cr[1],cr[2],cr[3],
        bndTransparent(bnd_theme.menuTheme.outlineColor));
    bndDropShadow(ctx,x,y,w,h,BND_MENU_RADIUS,
        BND_SHADOW_FEATHER,BND_SHADOW_ALPHA);
}

void bndTooltipBackground(NVGcontext* ctx, float x, float y, float w, float h) {
    NVGcolor shade_top, shade_down;
    
    bndInnerColors(&shade_top, &shade_down, &bnd_theme.tooltipTheme,
        BNDwidgetState.BND_DEFAULT, 0);
    bndInnerBox(ctx,x,y,w,h+1,
        BND_MENU_RADIUS,BND_MENU_RADIUS,BND_MENU_RADIUS,BND_MENU_RADIUS,
        shade_top, shade_down);
    bndOutlineBox(ctx,x,y,w,h+1,
        BND_MENU_RADIUS,BND_MENU_RADIUS,BND_MENU_RADIUS,BND_MENU_RADIUS,
        bndTransparent(bnd_theme.tooltipTheme.outlineColor));
    bndDropShadow(ctx,x,y,w,h,BND_MENU_RADIUS,
        BND_SHADOW_FEATHER,BND_SHADOW_ALPHA);
}

void bndMenuLabel(NVGcontext* ctx, float x, float y, float w, float h, int iconid, const(char)* label) {
    bndIconLabelValue(ctx,x,y,w,h,iconid,
        bnd_theme.menuTheme.textColor, BNDtextAlignment.BND_LEFT,
        BND_LABEL_FONT_SIZE, label, null);
}

void bndMenuItem(NVGcontext* ctx, float x, float y, float w, float h, BNDwidgetState state, int iconid, const(char)* label) {
    if (state != BNDwidgetState.BND_DEFAULT) {
        bndInnerBox(ctx,x,y,w,h,0,0,0,0, 
            bndOffsetColor(bnd_theme.menuItemTheme.innerSelectedColor, 
                bnd_theme.menuItemTheme.shadeTop), 
            bndOffsetColor(bnd_theme.menuItemTheme.innerSelectedColor, 
                bnd_theme.menuItemTheme.shadeDown));
        state = BNDwidgetState.BND_ACTIVE;
    }
    bndIconLabelValue(ctx,x,y,w,h,iconid,
        bndTextColor(&bnd_theme.menuItemTheme, state), BNDtextAlignment.BND_LEFT,
        BND_LABEL_FONT_SIZE, label, null);
}

void bndNodePort(NVGcontext* ctx, float x, float y, BNDwidgetState state, NVGcolor color) {
    nvgBeginPath(ctx);
    nvgCircle(ctx, x, y, BND_NODE_PORT_RADIUS);
    nvgStrokeColor(ctx,bnd_theme.nodeTheme.wiresColor);
    nvgStrokeWidth(ctx,1.0f);
    nvgStroke(ctx);
    nvgFillColor(ctx,(state != BNDwidgetState.BND_DEFAULT)?
        bndOffsetColor(color, BND_HOVER_SHADE):color);
    nvgFill(ctx);
}

void bndColoredNodeWire(NVGcontext* ctx, float x0, float y0, float x1, float y1, NVGcolor color0, NVGcolor color1) {
    float length = bnd_fmaxf(fabs(x1 - x0),fabs(y1 - y0));
    float delta = length*cast(float)bnd_theme.nodeTheme.noodleCurving/10.0f;
    
    nvgBeginPath(ctx);
    nvgMoveTo(ctx, x0, y0);
    nvgBezierTo(ctx, 
        x0 + delta, y0,
        x1 - delta, y1,
        x1, y1);
    NVGcolor colorw = bnd_theme.nodeTheme.wiresColor;
    colorw.a = (color0.a<color1.a)?color0.a:color1.a;
    nvgStrokeColor(ctx, colorw);
    nvgStrokeWidth(ctx, BND_NODE_WIRE_OUTLINE_WIDTH);
    nvgStroke(ctx);
    nvgStrokePaint(ctx, nvgLinearGradient(ctx, 
        x0, y0, x1, y1, 
        color0,
        color1));
    nvgStrokeWidth(ctx,BND_NODE_WIRE_WIDTH);
    nvgStroke(ctx);
}

void bndNodeWire(NVGcontext* ctx, float x0, float y0, float x1, float y1, BNDwidgetState state0, BNDwidgetState state1) {
    bndColoredNodeWire(ctx, x0, y0, x1, y1,
        bndNodeWireColor(&bnd_theme.nodeTheme, state0),
        bndNodeWireColor(&bnd_theme.nodeTheme, state1));
}

void bndNodeBackground(NVGcontext* ctx, float x, float y, float w, float h, BNDwidgetState state, int iconid, const(char)* label, NVGcolor titleColor) {
    bndInnerBox(ctx,x,y,w,BND_NODE_TITLE_HEIGHT+2,
        BND_NODE_RADIUS,BND_NODE_RADIUS,0,0,
        bndTransparent(bndOffsetColor(titleColor, BND_BEVEL_SHADE)), 
        bndTransparent(titleColor));
    bndInnerBox(ctx,x,y+BND_NODE_TITLE_HEIGHT-1,w,h+2-BND_NODE_TITLE_HEIGHT,
        0,0,BND_NODE_RADIUS,BND_NODE_RADIUS,
        bndTransparent(bnd_theme.nodeTheme.nodeBackdropColor), 
        bndTransparent(bnd_theme.nodeTheme.nodeBackdropColor));
    bndNodeIconLabel(ctx,
        x+BND_NODE_ARROW_AREA_WIDTH,y,
        w-BND_NODE_ARROW_AREA_WIDTH-BND_NODE_MARGIN_SIDE,BND_NODE_TITLE_HEIGHT,
        iconid, bnd_theme.regularTheme.textColor, 
        bndOffsetColor(titleColor, BND_BEVEL_SHADE), 
        BNDtextAlignment.BND_LEFT, BND_LABEL_FONT_SIZE, label);
    NVGcolor arrowColor;
    NVGcolor borderColor;
    switch(state) {
        default:
        case BNDwidgetState.BND_DEFAULT: {
            borderColor = nvgRGBf(0,0,0);
            arrowColor = bndOffsetColor(titleColor, -BND_BEVEL_SHADE);
            break;
        }
        case BNDwidgetState.BND_HOVER: {
            borderColor = bnd_theme.nodeTheme.nodeSelectedColor;
            arrowColor = bnd_theme.nodeTheme.nodeSelectedColor;
            break;
        }
        case BNDwidgetState.BND_ACTIVE: {
            borderColor = bnd_theme.nodeTheme.activeNodeColor;
            arrowColor = bnd_theme.nodeTheme.nodeSelectedColor;
            break;
        }
    }
    bndOutlineBox(ctx,x,y,w,h+1,
        BND_NODE_RADIUS,BND_NODE_RADIUS,BND_NODE_RADIUS,BND_NODE_RADIUS,
        bndTransparent(borderColor));
    /*
    bndNodeArrowDown(ctx, 
        x + BND_NODE_MARGIN_SIDE, y + BND_NODE_TITLE_HEIGHT-4, 
        BND_NODE_ARROW_SIZE, arrowColor);
    */
    bndDropShadow(ctx,x,y,w,h,BND_NODE_RADIUS,
        BND_SHADOW_FEATHER,BND_SHADOW_ALPHA);
}

void bndSplitterWidgets(NVGcontext* ctx, float x, float y, float w, float h) {
    NVGcolor insetLight = bndTransparent(
        bndOffsetColor(bnd_theme.backgroundColor, BND_SPLITTER_SHADE));
    NVGcolor insetDark = bndTransparent(
        bndOffsetColor(bnd_theme.backgroundColor, -BND_SPLITTER_SHADE));
    NVGcolor inset = bndTransparent(bnd_theme.backgroundColor);
    
    float x2 = x+w;
    float y2 = y+h;

    nvgBeginPath(ctx);
    nvgMoveTo(ctx, x, y2-13);
    nvgLineTo(ctx, x+13, y2);
    nvgMoveTo(ctx, x, y2-9);
    nvgLineTo(ctx, x+9, y2);
    nvgMoveTo(ctx, x, y2-5);
    nvgLineTo(ctx, x+5, y2);
    
    nvgMoveTo(ctx, x2-11, y);
    nvgLineTo(ctx, x2, y+11);
    nvgMoveTo(ctx, x2-7, y);
    nvgLineTo(ctx, x2, y+7);
    nvgMoveTo(ctx, x2-3, y);
    nvgLineTo(ctx, x2, y+3);
    
    nvgStrokeColor(ctx, insetDark);
    nvgStroke(ctx);

    nvgBeginPath(ctx);
    nvgMoveTo(ctx, x, y2-11);
    nvgLineTo(ctx, x+11, y2);
    nvgMoveTo(ctx, x, y2-7);
    nvgLineTo(ctx, x+7, y2);
    nvgMoveTo(ctx, x, y2-3);
    nvgLineTo(ctx, x+3, y2);
    
    nvgMoveTo(ctx, x2-13, y);
    nvgLineTo(ctx, x2, y+13);
    nvgMoveTo(ctx, x2-9, y);
    nvgLineTo(ctx, x2, y+9);
    nvgMoveTo(ctx, x2-5, y);
    nvgLineTo(ctx, x2, y+5);
    
    nvgStrokeColor(ctx, insetLight);
    nvgStroke(ctx);
    
    nvgBeginPath(ctx);
    nvgMoveTo(ctx, x, y2-12);
    nvgLineTo(ctx, x+12, y2);
    nvgMoveTo(ctx, x, y2-8);
    nvgLineTo(ctx, x+8, y2);
    nvgMoveTo(ctx, x, y2-4);
    nvgLineTo(ctx, x+4, y2);
    
    nvgMoveTo(ctx, x2-12, y);
    nvgLineTo(ctx, x2, y+12);
    nvgMoveTo(ctx, x2-8, y);
    nvgLineTo(ctx, x2, y+8);
    nvgMoveTo(ctx, x2-4, y);
    nvgLineTo(ctx, x2, y+4);
    
    nvgStrokeColor(ctx, inset);
    nvgStroke(ctx);
}

void bndJoinAreaOverlay(NVGcontext* ctx, float x, float y, float w, float h, int vertical, int mirror) {
    
    if (vertical) {
        float u = w;
        w = h; h = u;
    }
    
    float s = (w<h)?w:h;
    
    float x0,y0,x1,y1;
    if (mirror) {
        x0 = w;
        y0 = h;
        x1 = 0;
        y1 = 0;
        s = -s;
    } else {
        x0 = 0;
        y0 = 0;
        x1 = w;
        y1 = h;
    }
    
    float yc = (y0+y1)*0.5f;
    float s2 = s/2.0f;
    float s4 = s/4.0f;
    float s8 = s/8.0f;
    float x4 = x0+s4;
    
    float[2][] points = [
        [ x0,y0 ],
        [ x1,y0 ],
        [ x1,y1 ],
        [ x0,y1 ],
        [ x0,yc+s8 ],
        [ x4,yc+s8 ],
        [ x4,yc+s4 ],
        [ x0+s2,yc ],      
        [ x4,yc-s4 ],
        [ x4,yc-s8 ],
        [ x0,yc-s8 ]
    ];  
    
    nvgBeginPath(ctx);
    int count = points.sizeof / (float.sizeof*2);
    nvgMoveTo(ctx,x+points[0][vertical&1],y+points[0][(vertical&1)^1]);
    for (int i = 1; i < count; ++i) {
        nvgLineTo(ctx,x+points[i][vertical&1],y+points[i][(vertical&1)^1]);
    }
    
    nvgFillColor(ctx, nvgRGBAf(0,0,0,0.3));
    nvgFill(ctx);
}

////////////////////////////////////////////////////////////////////////////////

float bndLabelWidth(NVGcontext* ctx, int iconid, const(char)* label) {
    float w = BND_PAD_LEFT + BND_PAD_RIGHT;
    if (iconid >= 0) {
        w += BND_ICON_SHEET_RES;
    }
    if (label && (bnd_font >= 0)) {
        nvgFontFaceId(ctx, bnd_font);
        nvgFontSize(ctx, BND_LABEL_FONT_SIZE);
        w += nvgTextBounds(ctx, 1, 1, label, null, null);
    }
    return w;
}

float bndLabelHeight(NVGcontext* ctx, int iconid, const(char)* label, float width) {
	int h = BND_WIDGET_HEIGHT;
    width -= BND_TEXT_RADIUS*2;
    if (iconid >= 0) {
        width -= BND_ICON_SHEET_RES;
    }
    if (label && (bnd_font >= 0)) {
        nvgFontFaceId(ctx, bnd_font);
        nvgFontSize(ctx, BND_LABEL_FONT_SIZE);
        float[4] bounds;
        nvgTextBoxBounds(ctx, 1, 1, width, label, null, bounds.ptr);
        int bh = cast(int)(bounds[3] - bounds[1]) + BND_TEXT_PAD_DOWN;
        if (bh > h)
        	h = bh;
    }
    return h;
}

////////////////////////////////////////////////////////////////////////////////

void bndRoundedBox(NVGcontext* ctx, float x, float y, float w, float h, float cr0, float cr1, float cr2, float cr3) {
    float d;
    
    w = bnd_fmaxf(0, w);
    h = bnd_fmaxf(0, h);
    d = bnd_fminf(w, h);
    
    nvgMoveTo(ctx, x,y+h*0.5f);
    nvgArcTo(ctx, x,y, x+w,y, bnd_fminf(cr0, d/2));
    nvgArcTo(ctx, x+w,y, x+w,y+h, bnd_fminf(cr1, d/2));
    nvgArcTo(ctx, x+w,y+h, x,y+h, bnd_fminf(cr2, d/2));
    nvgArcTo(ctx, x,y+h, x,y, bnd_fminf(cr3, d/2));
    nvgClosePath(ctx);
}

NVGcolor bndTransparent(NVGcolor color) {
    color.a *= BND_TRANSPARENT_ALPHA;
    return color;
}

NVGcolor bndOffsetColor(NVGcolor color, int delta) {
    float offset = cast(float)delta / 255.0f;
    return delta?(
        nvgRGBAf(
            bnd_clamp(color.r+offset,0,1),
            bnd_clamp(color.g+offset,0,1),
            bnd_clamp(color.b+offset,0,1),
            color.a)
    ):color;
}

void bndBevel(NVGcontext* ctx, float x, float y, float w, float h) {
    nvgStrokeWidth(ctx, 1);
    
    x += 0.5f;
    y += 0.5f;
    w -= 1;
    h -= 1;
    
    nvgBeginPath(ctx);
    nvgMoveTo(ctx, x, y+h);
    nvgLineTo(ctx, x+w, y+h);
    nvgLineTo(ctx, x+w, y);
    nvgStrokeColor(ctx, bndTransparent(
        bndOffsetColor(bnd_theme.backgroundColor, -BND_BEVEL_SHADE)));
    nvgStroke(ctx);
    
    nvgBeginPath(ctx);
    nvgMoveTo(ctx, x, y+h);
    nvgLineTo(ctx, x, y);
    nvgLineTo(ctx, x+w, y);
    nvgStrokeColor(ctx, bndTransparent(
        bndOffsetColor(bnd_theme.backgroundColor, BND_BEVEL_SHADE)));
    nvgStroke(ctx);
}

void bndBevelInset(NVGcontext* ctx, float x, float y, float w, float h, float cr2, float cr3) {
    float d;
    
    y -= 0.5f;
    d = bnd_fminf(w, h);
    cr2 = bnd_fminf(cr2, d/2);
    cr3 = bnd_fminf(cr3, d/2);
    
    nvgBeginPath(ctx);
    nvgMoveTo(ctx, x+w,y+h-cr2);
    nvgArcTo(ctx, x+w,y+h, x,y+h, cr2);
    nvgArcTo(ctx, x,y+h, x,y, cr3);
    
    NVGcolor bevelColor = bndOffsetColor(bnd_theme.backgroundColor, BND_INSET_BEVEL_SHADE);
    
    nvgStrokeWidth(ctx, 1);
    nvgStrokePaint(ctx,
        nvgLinearGradient(ctx,
            x,y+h-bnd_fmaxf(cr2,cr3)-1,
            x,y+h-1,
        nvgRGBAf(bevelColor.r, bevelColor.g, bevelColor.b, 0),
        bevelColor));
    nvgStroke(ctx);
}

void bndBackground(NVGcontext* ctx, float x, float y, float w, float h) {
    nvgBeginPath(ctx);
    nvgRect(ctx, x, y, w, h);
    nvgFillColor(ctx, bnd_theme.backgroundColor);
    nvgFill(ctx);
}

void bndIcon(NVGcontext* ctx, float x, float y, int iconid) {
    int ix, iy, u, v;
    if (bnd_icon_image < 0) return; // no icons loaded
    
    ix = iconid & 0xff;
    iy = (iconid>>8) & 0xff;
    u = BND_ICON_SHEET_OFFSET_X + ix*BND_ICON_SHEET_GRID;
    v = BND_ICON_SHEET_OFFSET_Y + iy*BND_ICON_SHEET_GRID;
    
    nvgBeginPath(ctx);
    nvgRect(ctx,x,y,BND_ICON_SHEET_RES,BND_ICON_SHEET_RES);
    nvgFillPaint(ctx,
        nvgImagePattern(ctx,x-u,y-v,
        BND_ICON_SHEET_WIDTH,
        BND_ICON_SHEET_HEIGHT,
        0,bnd_icon_image,1));
    nvgFill(ctx);
}

void bndDropShadow(NVGcontext* ctx, float x, float y, float w, float h, float r, float feather, float alpha) {
    
    nvgBeginPath(ctx);
    y += feather;
    h -= feather;
    
    nvgMoveTo(ctx, x-feather, y-feather);
    nvgLineTo(ctx, x, y-feather);
    nvgLineTo(ctx, x, y+h-feather);
    nvgArcTo(ctx, x,y+h,x+r,y+h,r);
    nvgArcTo(ctx, x+w,y+h,x+w,y+h-r,r);
    nvgLineTo(ctx, x+w, y-feather);
    nvgLineTo(ctx, x+w+feather, y-feather);
    nvgLineTo(ctx, x+w+feather, y+h+feather);
    nvgLineTo(ctx, x-feather, y+h+feather);
    nvgClosePath(ctx);
    
    nvgFillPaint(ctx, nvgBoxGradient(ctx,
        x - feather*0.5f,y - feather*0.5f,
        w + feather,h+feather,
        r+feather*0.5f,
        feather,
        nvgRGBAf(0,0,0,alpha*alpha), 
        nvgRGBAf(0,0,0,0)));
    nvgFill(ctx);
}

void bndInnerBox(NVGcontext* ctx, float x, float y, float w, float h, float cr0, float cr1, float cr2, float cr3, NVGcolor shade_top, NVGcolor shade_down) {
    nvgBeginPath(ctx);
    bndRoundedBox(ctx,x+1,y+1,w-2,h-3,bnd_fmaxf(0,cr0-1),
        bnd_fmaxf(0,cr1-1),bnd_fmaxf(0,cr2-1),bnd_fmaxf(0,cr3-1));
    nvgFillPaint(ctx,((h-2)>w)?
        nvgLinearGradient(ctx,x,y,x+w,y,shade_top,shade_down):
        nvgLinearGradient(ctx,x,y,x,y+h,shade_top,shade_down));
    nvgFill(ctx);
}

void bndOutlineBox(NVGcontext* ctx, float x, float y, float w, float h, float cr0, float cr1, float cr2, float cr3, NVGcolor color) {
    nvgBeginPath(ctx);
    bndRoundedBox(ctx,x+0.5f,y+0.5f,w-1,h-2,cr0,cr1,cr2,cr3);
    nvgStrokeColor(ctx,color);
    nvgStrokeWidth(ctx,1);
    nvgStroke(ctx);
}

void bndSelectCorners(float* radiuses, float r, int flags) {
    radiuses[0] = (flags & BNDcornerFlags.BND_CORNER_TOP_LEFT)?0:r;
    radiuses[1] = (flags & BNDcornerFlags.BND_CORNER_TOP_RIGHT)?0:r;
    radiuses[2] = (flags & BNDcornerFlags.BND_CORNER_DOWN_RIGHT)?0:r;
    radiuses[3] = (flags & BNDcornerFlags.BND_CORNER_DOWN_LEFT)?0:r;
}

void bndInnerColors(NVGcolor* shade_top, NVGcolor* shade_down, const(BNDwidgetTheme)* theme, BNDwidgetState state, int flipActive) {

    switch(state) {
        default:
        case BNDwidgetState.BND_DEFAULT: {
            *shade_top = bndOffsetColor(theme.innerColor, theme.shadeTop);
            *shade_down = bndOffsetColor(theme.innerColor, theme.shadeDown);
            break;
        }
        case BNDwidgetState.BND_HOVER: {
            NVGcolor color = bndOffsetColor(theme.innerColor, BND_HOVER_SHADE);
            *shade_top = bndOffsetColor(color, theme.shadeTop);
            *shade_down = bndOffsetColor(color, theme.shadeDown);
            break;
        }
        case BNDwidgetState.BND_ACTIVE: {
            *shade_top = bndOffsetColor(theme.innerSelectedColor, 
                flipActive?theme.shadeDown:theme.shadeTop);
            *shade_down = bndOffsetColor(theme.innerSelectedColor, 
                flipActive?theme.shadeTop:theme.shadeDown);
            break;
        }
    }
}

NVGcolor bndTextColor(const(BNDwidgetTheme)* theme, BNDwidgetState state) {
    return (state == BNDwidgetState.BND_ACTIVE)?theme.textSelectedColor:theme.textColor;
}

void bndIconLabelValue(NVGcontext* ctx, float x, float y, float w, float h, int iconid, NVGcolor color, int align_, float fontsize, const(char)* label, const(char)* value) {
    float pleft = BND_PAD_LEFT;
    if (label) {
        if (iconid >= 0) {
            bndIcon(ctx,x+4,y+2,iconid);
            pleft += BND_ICON_SHEET_RES;
        }    
        
        if (bnd_font < 0) return;
        nvgFontFaceId(ctx, bnd_font);
        nvgFontSize(ctx, fontsize);
        nvgBeginPath(ctx);
        nvgFillColor(ctx, color);
        if (value) {
            float label_width = nvgTextBounds(ctx, 1, 1, label, null, null);
            float sep_width = nvgTextBounds(ctx, 1, 1,
                BND_LABEL_SEPARATOR, null, null);
            
            nvgTextAlign(ctx, NVGalign.NVG_ALIGN_LEFT|NVGalign.NVG_ALIGN_BASELINE);
            x += pleft;
            if (align_ == BNDtextAlignment.BND_CENTER) {
                float width = label_width + sep_width
                    + nvgTextBounds(ctx, 1, 1, value, null, null);
                x += ((w-BND_PAD_RIGHT-pleft)-width)*0.5f;
            }
            y += BND_WIDGET_HEIGHT-BND_TEXT_PAD_DOWN;
            nvgText(ctx, x, y, label, null);
            x += label_width;
            nvgText(ctx, x, y, BND_LABEL_SEPARATOR, null);
            x += sep_width;
            nvgText(ctx, x, y, value, null);
        } else {
            nvgTextAlign(ctx, 
                (align_==BNDtextAlignment.BND_LEFT)?(NVGalign.NVG_ALIGN_LEFT|NVGalign.NVG_ALIGN_BASELINE):
                (NVGalign.NVG_ALIGN_CENTER|NVGalign.NVG_ALIGN_BASELINE));
            nvgTextBox(ctx,x+pleft,y+BND_WIDGET_HEIGHT-BND_TEXT_PAD_DOWN,
                w-BND_PAD_RIGHT-pleft,label, null);
        }
    } else if (iconid >= 0) {
        bndIcon(ctx,x+2,y+2,iconid);
    }
}

void bndNodeIconLabel(NVGcontext* ctx, float x, float y, float w, float h, int iconid, NVGcolor color, NVGcolor shadowColor, int align_, float fontsize, const(char)* label) {
    if (label && (bnd_font >= 0)) {
        nvgFontFaceId(ctx, bnd_font);
        nvgFontSize(ctx, fontsize);
        nvgBeginPath(ctx);
        nvgTextAlign(ctx, NVGalign.NVG_ALIGN_LEFT|NVGalign.NVG_ALIGN_BASELINE);
        nvgFillColor(ctx, shadowColor);
        nvgFontBlur(ctx, BND_NODE_TITLE_FEATHER);
        nvgTextBox(ctx,x+1,y+h+3-BND_TEXT_PAD_DOWN,
            w,label, null);
        nvgFillColor(ctx, color);
        nvgFontBlur(ctx, 0);
        nvgTextBox(ctx,x,y+h+2-BND_TEXT_PAD_DOWN,
            w,label, null);
    }
    if (iconid >= 0) {
        bndIcon(ctx,x+w-BND_ICON_SHEET_RES,y+3,iconid);
    }
}

int bndIconLabelTextPosition(NVGcontext* ctx, float x, float y, float w, float h, int iconid, float fontsize, const(char)* label, int px, int py) {
    float[4] bounds;
    float pleft = BND_TEXT_RADIUS;
    if (!label) return -1;
    if (iconid >= 0)
        pleft += BND_ICON_SHEET_RES;

    if (bnd_font < 0) return -1;

    x += pleft;
    y += BND_WIDGET_HEIGHT - BND_TEXT_PAD_DOWN;

    nvgFontFaceId(ctx, bnd_font);
    nvgFontSize(ctx, fontsize);
    nvgTextAlign(ctx, NVGalign.NVG_ALIGN_LEFT|NVGalign.NVG_ALIGN_BASELINE);

    w -= BND_TEXT_RADIUS + pleft;

    float asc, desc, lh;
    static NVGtextRow[BND_MAX_ROWS] rows;
    int nrows = nvgTextBreakLines(
        ctx, label, null, w, rows.ptr, BND_MAX_ROWS);
    if (nrows == 0) return 0;
    nvgTextBoxBounds(ctx, x, y, w, label, null, bounds.ptr);
    nvgTextMetrics(ctx, &asc, &desc, &lh);

    // calculate vertical position
    int row = cast(int)bnd_clamp(cast(int)(cast(float)(py - bounds[1]) / lh), 0, nrows - 1);
    // search horizontal position
    static NVGglyphPosition[BND_MAX_GLYPHS] glyphs;
    int nglyphs = nvgTextGlyphPositions(
        ctx, x, y, rows[row].start, rows[row].end + 1, glyphs.ptr, BND_MAX_GLYPHS);
    int col, p = 0;
    for (col = 0; col < nglyphs && glyphs[col].x < px; ++col)
        p = cast(int)(glyphs[col].str - label);
    // see if we should move one character further
    if (col > 0 && col < nglyphs && glyphs[col].x - px < px - glyphs[col - 1].x)
        p = cast(int)(glyphs[col].str - label);
    return p;
}

void bndCaretPosition(NVGcontext* ctx, float x, float y, float desc, float lineHeight, const(char)* caret, NVGtextRow* rows, int nrows, int* cr, float* cx, float* cy) {
    static NVGglyphPosition[BND_MAX_GLYPHS] glyphs;
    int r,nglyphs;
    for (r=0; r < nrows && rows[r].end < caret; ++r) {}
    *cr = r;
    *cx = x;
    *cy = y-lineHeight-desc + r*lineHeight;
    if (nrows == 0) return;
    *cx = rows[r].minx;
    nglyphs = nvgTextGlyphPositions(
        ctx, x, y, rows[r].start, rows[r].end+1, glyphs.ptr, BND_MAX_GLYPHS);
    for (int i=0; i < nglyphs; ++i) {
        *cx=glyphs[i].x;
        if (glyphs[i].str == caret) break;
    }
}

void bndIconLabelCaret(NVGcontext* ctx, float x, float y, float w, float h, int iconid, NVGcolor color, float fontsize, const(char)* label, NVGcolor caretcolor, int cbegin, int cend) {
    float pleft = BND_TEXT_RADIUS;
    if (!label) return;
    if (iconid >= 0) {
        bndIcon(ctx,x+4,y+2,iconid);
        pleft += BND_ICON_SHEET_RES;
    }
    
    if (bnd_font < 0) return;
    
    x+=pleft;
    y+=BND_WIDGET_HEIGHT-BND_TEXT_PAD_DOWN;

    nvgFontFaceId(ctx, bnd_font);
    nvgFontSize(ctx, fontsize);
    nvgTextAlign(ctx, NVGalign.NVG_ALIGN_LEFT|NVGalign.NVG_ALIGN_BASELINE);

    w -= BND_TEXT_RADIUS+pleft;

    if (cend >= cbegin) {
        int c0r,c1r;
        float c0x,c0y,c1x,c1y;
        float desc,lh;
        static NVGtextRow[BND_MAX_ROWS] rows;
        int nrows = nvgTextBreakLines(
            ctx, label, label+cend+1, w, rows.ptr, BND_MAX_ROWS);
        nvgTextMetrics(ctx, null, &desc, &lh);

        bndCaretPosition(ctx, x, y, desc, lh, label+cbegin,
            rows.ptr, nrows, &c0r, &c0x, &c0y);
        bndCaretPosition(ctx, x, y, desc, lh, label+cend,
            rows.ptr, nrows, &c1r, &c1x, &c1y);
        
        nvgBeginPath(ctx);
        if (cbegin == cend) {
            nvgFillColor(ctx, nvgRGBf(0.337,0.502,0.761));
            nvgRect(ctx, c0x-1, c0y, 2, lh+1);
        } else {
            nvgFillColor(ctx, caretcolor);
            if (c0r == c1r) {
                nvgRect(ctx, c0x-1, c0y, c1x-c0x+1, lh+1);
            } else {
                int blk=c1r-c0r-1;
                nvgRect(ctx, c0x-1, c0y, x+w-c0x+1, lh+1);
                nvgRect(ctx, x, c1y, c1x-x+1, lh+1);

                if (blk)
                    nvgRect(ctx, x, c0y+lh, w, blk*lh+1);
            }
        }
        nvgFill(ctx);
    }
    
    nvgBeginPath(ctx);
    nvgFillColor(ctx, color);
    nvgTextBox(ctx,x,y,w,label, null);
}

void bndCheck(NVGcontext* ctx, float ox, float oy, NVGcolor color) {
    nvgBeginPath(ctx);
    nvgStrokeWidth(ctx,2);
    nvgStrokeColor(ctx,color);
    nvgLineCap(ctx,NVGlineCap.NVG_BUTT);
    nvgLineJoin(ctx,NVGlineCap.NVG_MITER);
    nvgMoveTo(ctx,ox+4,oy+5);
    nvgLineTo(ctx,ox+7,oy+8);
    nvgLineTo(ctx,ox+14,oy+1);
    nvgStroke(ctx);
}

void bndArrow(NVGcontext* ctx, float x, float y, float s, NVGcolor color) {
    nvgBeginPath(ctx);
    nvgMoveTo(ctx,x,y);
    nvgLineTo(ctx,x-s,y+s);
    nvgLineTo(ctx,x-s,y-s);
    nvgClosePath(ctx);
    nvgFillColor(ctx,color);
    nvgFill(ctx);
}

void bndUpDownArrow(NVGcontext* ctx, float x, float y, float s, NVGcolor color) {
    float w;

    nvgBeginPath(ctx);
    w = 1.1f*s;
    nvgMoveTo(ctx,x,y-1);
    nvgLineTo(ctx,x+0.5*w,y-s-1);
    nvgLineTo(ctx,x+w,y-1);
    nvgClosePath(ctx);
    nvgMoveTo(ctx,x,y+1);
    nvgLineTo(ctx,x+0.5*w,y+s+1);
    nvgLineTo(ctx,x+w,y+1);
    nvgClosePath(ctx);
    nvgFillColor(ctx,color);
    nvgFill(ctx);
}

void bndNodeArrowDown(NVGcontext* ctx, float x, float y, float s, NVGcolor color) {
    float w;
    nvgBeginPath(ctx);
    w = 1.0f*s;
    nvgMoveTo(ctx,x,y);
    nvgLineTo(ctx,x+0.5*w,y-s);
    nvgLineTo(ctx,x-0.5*w,y-s);
    nvgClosePath(ctx);
    nvgFillColor(ctx,color);
    nvgFill(ctx);
}

void bndScrollHandleRect(float* x, float* y, float* w, float* h, float offset, float size) {
    size = bnd_clamp(size,0,1);
    offset = bnd_clamp(offset,0,1);
    if ((*h) > (*w)) {
        float hs = bnd_fmaxf(size*(*h), (*w)+1);
        *y = (*y) + ((*h)-hs)*offset;
        *h = hs;
    } else {
        float ws = bnd_fmaxf(size*(*w), (*h)-1);
        *x = (*x) + ((*w)-ws)*offset;
        *w = ws;
    }
}

NVGcolor bndNodeWireColor(const(BNDnodeTheme)* theme, BNDwidgetState state) {
    switch(state) {
        default:
        case BNDwidgetState.BND_DEFAULT: return nvgRGBf(0.5f,0.5f,0.5f);
        case BNDwidgetState.BND_HOVER: return theme.wireSelectColor;
        case BNDwidgetState.BND_ACTIVE: return theme.activeNodeColor;
    }
}

////////////////////////////////////////////////////////////////////////////////