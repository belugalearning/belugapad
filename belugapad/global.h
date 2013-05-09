//
//  global.h
//  belugapad
//
//  Created by Gareth Jenkins on 03/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define RELEASE_MODE 1
#define USE_TESTFLIGHT_SDK 0

#define BUNDLE_FULL_PATH(_filePath_) [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:_filePath_]

#define DOWNLOAD_USER_STATE_COMPLETE @"DOWNLOAD_USER_STATE_COMPLETE"

#define GENERIC_FONT @"STHeitiTC-Light"
#define TITLE_FONT @"STHeitiTC-Light"
//#define TITLE_FONT @"Helvetica-Bold"
#define TITLE_SIZE 90
#define TITLE_OPACITY 15
#define TITLE_COLOR3 ccc3(255, 255, 255)

#define BKG_COLOR4 ccc4(235, 246, 252, 255)

#define UNDERLAY_FILENAME @"UNDERLAY_FILENAME"
#define OVERLAY_FILENAME @"OVERLAY_FILENAME"


#define POS_X @"POS_X"
#define POS_Y @"POS_Y"
#define POS @"POS"
#define ROT @"ROT"

#define OBJ_COLS @"OBJ_COLS"
#define OBJ_ROWS @"OBJ_ROWS"
#define OBJ_UNITCOUNT @"OBJ_UNITCOUNT"
#define OBJ_MATRIXPOS @"OBJ_MATRIXPOS"
#define OBJ_CHILDMATRIX @"OBJ_CHILDMATRIX"
#define OBJ_CHILD @"OBJ_CHILD"

#define UNIT_SIZE 50.0f
#define HALF_SIZE 25.0f

#define OFFSET @"OFFSET"
#define MOUNT @"MOUNT"
#define MOUNTED_OBJECT @"MOUNTED_OBJECT"
#define MOUNTED_OBJECTS @"MOUNTED_OBJECTS"
#define DISABLED @"DISABLED"

#define ENABLE_CALCULATOR @"ENABLE_CALCULATOR"
#define ENABLE_WHEEL @"ENABLE_WHEEL"


#define PHYS_BODY @"PHYS_BODY"

#define PICKUP_PROXIMITY 70.0f
#define DROP_PROXIMITY 70.0f

#define FLOAT_PICKUP_PROXIMITY 50.0f

#define TARGET_GO @"TARGET_GO"


#define NLINE_PRI_MARKER_YBASE 50.0f
#define NLINE_PRI_SPACEBASE 180.0f
#define NLINE_MARKER_FONT @"visgrad1.fnt"

#define PROBLEM_DESC_FONT @"STHeitiTC-Light"
#define PROBLEM_DESC_FONT_SIZE 35
#define PROBLEM_SUBTITLE_FONT_SIZE 20

#define SOURCE @"Source Sans Pro"
#define CHANGO @"Chango"

#define MY_SPRITE @"MY_SPRITE"

#define RENDER_IMAGE_NAME @"RENDER_IMAGE_NAME"

// tool definition files
#define SCALE_MIN @"SCALE_MIN"
#define SCALE_MAX @"SCALE_MAX"
#define SCALING_PASS_THRU @"SCALING_PASS_THRU"

// problem definition files
#define PROBLEM_DESCRIPTION @"PROBLEM_DESCRIPTION"
#define PROBLEM_SUBTITLE @"PROBLEM_SUBTITLE"
#define INIT_OBJECTS @"INIT_OBJECTS"
#define INIT_BARS @"INIT_BARS"
#define INIT_CAGES @"INIT_CAGES"
#define TAG @"TAG"
#define HIDDEN @"HIDDEN"
#define DIMENSION_COLS @"DIMENSION_COLS"
#define DIMENSION_ROWS @"DIMENSION_ROWS"
#define DIMENSION_UNIT_COUNT @"DIMENSION_UNIT_COUNT"
#define INIT_CONTAINERS @"INIT_CONTAINERS"
#define CAPACITY_COUNT @"CAPACITY_COUNT"
#define MAX_OBJECT_SIZE @"MAX_OBJECT_SIZE"
#define CAPACITY_SIZE @"CAPACITY_SIZE"
#define SOLUTIONS @"SOLUTIONS"
#define SOLUTION_SCORE @"SOLUTION_SCORE"
#define REJECT_MODE @"REJECT_MODE"
#define REJECT_TYPE @"REJECT_TYPE"
#define EVAL_MODE @"EVAL_MODE"
#define EVAL_TYPE @"EVAL_TYPE"
#define CLAUSES @"CLAUSES"
#define ITEM1_CONTAINER_TAG @"ITEM1_CONTAINER_TAG"
#define ITEM2_CONTAINER_TAG @"ITEM2_CONTAINER_TAG"
#define ITEM1_VALUE @"ITEM1_VALUE"
#define ITEM2_VALUE @"ITEM2_VALUE"
#define CLAUSE_TYPE @"CLAUSE_TYPE"
#define ITEM1_OBJECT_TAG @"ITEM1_OBJECT_TAG"
#define MATCHES_IN_SOLUTIONS @"MATCHES_IN_SOLUTIONS"
#define SELECTED @"SELECTED"
#define ANIMATE_ME @"ANIMATE_ME"
#define SOLUTION_TYPE @"SOLUTION_TYPE"
#define X_OFFSET @"X_OFFSET"
#define COLUMN_SPACING @"COLUMN_SPACING"
#define DISABLE_AUDIO_COUNTING @"DISABLE_AUDIO_COUNTING"

// PlaceValue specifics

#define PERCENT @"PERCENT"
#define FRACTION @"FRACTION"
#define SOLUTION @"SOLUTION"
#define COL_BASE_VALUE @"COL_BASE_VALUE"
#define FIRST_COL_VALUE @"FIRST_COL_VALUE"
#define COL_VALUE @"COL_VALUE"
#define COL_LABEL @"COL_LABEL"
#define NUMBER_COLS @"NUMBER_COLS"
#define DEFAULT_COL @"DEFAULT_COL"
#define ROPES_PER_COL @"ROPES_PER_COL"
#define ROWS_PER_COL @"ROWS_PER_COL"
#define ALLOW_CONDENSING @"ALLOW_CONDENSING"
#define ALLOW_MULCHING @"ALLOW_MULCHING"
#define PUT_IN_COL @"PUT_IN_COL"
#define PUT_IN_ROW @"PUT_IN_ROW"
#define NUMBER @"NUMBER"
#define NUMBER_NEGATIVE @"NUMBER_NEGATIVE"
#define COUNT_SEQUENCE @"COUNT_SEQUENCE"
#define TOTAL_COUNT @"TOTAL_COUNT"
#define TOTAL_COUNT_AND_COUNT_SEQUENCE @"TOTAL_COUNT_AND_COUNT_SEQUENCE"
#define MATRIX_MATCH @"MATRIX_MATCH"
#define GRID_MATCH @"GRID_MATCH"
#define SOLUTION_MATRIX @"SOLUTION_MATRIX"
#define SOLUTION_VALUE @"SOLUTION_VALUE"
#define SHOW_CAGE @"SHOW_CAGE"
#define SHOW_NEG_CAGE @"SHOW_NEG_CAGE"
#define SHOW_COUNT @"SHOW_COUNT"
#define SHOW_VALUE @"SHOW_VALUE"
#define SHOW_COUNT_BLOCK @"SHOW_COUNT_BLOCK"
#define SHOW_COL_HEADER @"SHOW_COL_HEADER"
#define ALLOW_MULTIPLE_MOUNT @"ALLOW_MULTIPLE_MOUNT"
#define COLUMN_SPRITES @"COLUMN_SPRITES"
#define OBJECT_VALUE @"OBJECT_VALUE"
#define SPRITE_FILENAME @"SPRITE_FILENAME"
#define SHOW_BASE_SELECTION @"SHOW_BASE_SELECTION"
#define CUSTOM_COLUMN_HEADERS @"CUSTOM_COLUMN_HEADERS"
#define COLUMN_CAGES @"COLUMN_CAGES"
#define COLUMN_NEG_CAGES @"COLUMN_NEG_CAGES"
#define NUMBER_PRE_COUNTED @"NUMBER_PRE_COUNTED"
#define CAGE_POS_DISABLE_ADD @"CAGE_POS_DISABLE_ADD"
#define CAGE_NEG_DISABLE_ADD @"CAGE_NEG_DISABLE_ADD"
#define CAGE_POS_DISABLE_DELETE @"CAGE_POS_DISABLE_DELETE"
#define CAGE_NEG_DISABLE_DELETE @"CAGE_NEG_DISABLE_DELETE"
#define COLUMN_ROWS @"COLUMN_ROWS"
#define COLUMN_ROPES @"COLUMN_ROPES"
#define DISABLE_ADD @"DISABLE_ADD" // Disable adding from cage
#define DISABLE_DEL @"DISABLE_DEL" // Disable deleting to cage
#define ALLOW_DESELECTION @"ALLOW_DESELECTION"
#define SHOW_RESET @"SHOW_RESET"
#define FADE_COUNT @"FADE_COUNT"
#define CAGE_SPRITES @"CAGE_SPRITES"
#define POS_CAGE @"POS_CAGE"
#define NEG_CAGE @"NEG_CAGE"
#define PICKUP_SPRITE_FILENAME @"PICKUP_SPRITE_FILENAME"
#define PROXIMITY_SPRITE_FILENAME @"PROXIMITY_SPRITE_FILENAME"
#define ALLOW_PANNING @"ALLOW_PANNING"
#define MULTIPLE_BLOCK_PICKUP @"MULTIPLE_BLOCK_PICKUP"
#define MULTIPLE_BLOCK_PICKUP_DEFAULTS @"MULTIPLE_BLOCK_PICKUP_DEFAULTS"
#define MULTIPLE_BLOCK_PICKUP_MIN @"MULTIPLE_BLOCK_PICKUP_MIN"
#define MULTIPLE_BLOCK_PICKUP_MAX @"MULTIPLE_BLOCK_PICKUP_MAX"
#define SHOW_MULTIPLE_BLOCKS_FROM_CAGE @"SHOW_MULTIPLE_BLOCKS_FROM_CAGE"
#define IS_NEGATIVE_PROBLEM @"IS_NEGATIVE_PROBLEM"
#define CAGE_DEFAULT_VALUE @"CAGE_DEFAULT_VALUE"
#define EXPLODE_MODE @"EXPLODE_MODE"
#define AUTO_SELECT_BASE_VALUE @"AUTO_SELECT_BASE_VALUE"
#define SHOW_COLUMN_TOTAL_COUNT @"SHOW_COLUMN_TOTAL_COUNT"
#define SHOW_COLUMN_USER_COUNT @"SHOW_COLUMN_USER_COUNT"
#define SHOW_MORE_LESS_ARROWS @"SHOW_MORE_LESS_ARROWS"
#define COUNT_USER_BLOCKS @"COUNT_USER_BLOCKS"
#define COLUMN_TOTAL_COUNT_TYPE @"COLUMN_TOTAL_COUNT_TYPE"


// generic tools keys -- formerly from BlockFloating

#define OPERATOR_MODE @"OPERATOR_MODE"
#define SOLUTION_DISPLAY_TEXT @"SOLUTION_DISPLAY_TEXT"
#define INCOMPLETE_DISPLAY_TEXT @"INCOMPLETE_DISPLAY_TEXT"
#define IS_INTRO_PLIST @"IS_INTRO_PLIST"
#define PLAY_SOUND @"PLAY_SOUND"


//clause types
#define SIZE_EQUAL_TO @"SIZE_EQUAL_TO"
#define SIZE_LESS_THAN @"SIZE_LESS_THAN"
#define SIZE_GREATER_THAN @"SIZE_GREATER_THAN"

#define COUNT_EQUAL_TO @"COUNT_EQUAL_TO"
#define COUNT_LESS_THAN @"COUNT_LESS_THAN"
#define COUNT_GREATER_THAN @"COUNT_GREATER_THAN"

#define IS_CONTAINED_BY @"IS_CONTAINED_BY"

#define OBJECT_OF_SIZE @"OBJECT_OF_SIZE"

//daemon params
#define ANIMATIONS_ENABLED @"ANIMATIONS_ENABLED"


//ghost parameters
#define GHOST_DURATION_MOVE 1.5f
#define GHOST_DURATION_STAY 1.0f
#define GHOST_DURATION_FADE 1.0f
#define GHOST_OPACITY 150
#define GHOST_TINT_G 100

#define TUTORIAL_TIME_START 4.0f
#define TUTORIAL_TIME_REPEAT 10.0f


#define PLACEVALUE_COLUMN @"PLACEVALUE_COLUMN"
#define PLACEVALUE_ROW @"PLACEVALUE_ROW"
#define PLACEVALUE_ROPE @"PLACEVALUE_ROPE"

#define TOOL_KEY @"TOOL_KEY"
#define EXPRESSION_FILE @"EXPRESSION_FILE"

#define DEFAULT_SCALE @"DEFAULT_SCALE"

// meta question params
#define META_QUESTION @"META_QUESTION"
#define META_QUESTION_ANSWERS @"META_QUESTION_ANSWERS"
#define META_QUESTION_ANSWER_MODE @"META_QUESTION_ANSWER_MODE"
#define META_QUESTION_EVAL_MODE @"META_QUESTION_EVAL_MODE"
#define META_QUESTION_TITLE @"META_QUESTION_TITLE"
#define META_ANSWER_TEXT @"META_ANSWER_TEXT"
#define META_ANSWER_VALUE @"META_ANSWER_VALUE"
#define META_ANSWER_SELECTED @"META_ANSWER_SELECTED"
#define META_ANSWER_SHOWN_SELECTED @"META_ANSWER_SHOWN_SELECTED"
#define META_QUESTION_COMPLETE_TEXT @"META_QUESTION_COMPLETE_TEXT"
#define META_QUESTION_INCOMPLETE_TEXT @"META_QUESTION_INCOMPLETE_TEXT"
#define META_QUESTION_RANDOMISE_ANSWERS @"META_QUESTION_RANDOMISE_ANSWERS"
#define SHOW_AT_START @"SHOW_AT_START"


//nline params
#define START_VALUE @"START_VALUE"
#define SEGMENT_VALUE @"SEGMENT_VALUE"
#define MIN_VALUE @"MIN_VALUE"
#define MAX_VALUE @"MAX_VALUE"


// column addition
#define NUMBER_A @"NUMBER_A"
#define NUMBER_B @"NUMBER_B"

// partition tool

#define LENGTH @"LENGTH"
#define LOCKED @"LOCKED"
#define LABEL @"LABEL"
#define QUANTITY @"QUANTITY"
#define NUMBER_TO_STACK @"NUMBER_TO_STACK"
#define USE_BLOCK_SCALING @"USE_BLOCK_SCALING"
#define SHOW_BADGES @"SHOW_BADGES"
#define INIT_HINTS @"INIT_HINTS"
#define BAR_ASSISTANCE @"BAR_ASSISTANCE"

// dotgrid tool

#define DOTGRID_EVAL_TYPE @"DOTGRID_EVAL_TYPE"
#define DOTGRID_EVAL_DIVIDEND @"DOTGRID_EVAL_DIVIDEND"
#define DOTGRID_EVAL_DIVISOR @"DOTGRID_EVAL_DIVISOR"
#define DOTGRID_EVAL_TOTALSIZE @"DOTGRID_EVAL_TOTALSIZE"
#define DRAW_MODE @"DRAW_MODE"
#define ANCHOR_SPACE @"ANCHOR_SPACE"
#define START_X @"START_X"
#define START_Y @"START_Y"
#define END_X @"END_X"
#define END_Y @"END_Y"
#define SHOW_MOVE @"SHOW_MOVE"
#define SHOW_RESIZE @"SHOW_RESIZE"
#define HIDDEN_ROWS @"HIDDEN_ROWS"
#define PRE_COUNTED_TILES @"PRE_COUNTED_TILES"
#define DISABLE_COUNTING @"DISABLE_COUNTING"
#define DO_NOT_SIMPLIFY_FRACTIONS @"DO_NOT_SIMPLIFY_FRACTIONS"
#define SHOW_DRAGGABLE_BLOCK @"SHOW_DRAGGABLE_BLOCK"
#define RENDER_SHAPE_DIMENSIONS @"RENDER_SHAPE_DIMENSIONS"
#define SELECT_WHOLE_SHAPE @"SELECT_WHOLE_SHAPE"
#define USE_SHAPE_GROUPS @"USE_SHAPE_GROUPS"
#define SHAPE_GROUP_SIZE @"SHAPE_GROUP_SIZE"
#define SHAPE_BASE_SIZE @"SHAPE_BASE_SIZE"
#define DISABLE_DRAWING @"DISABLE_DRAWING"
#define SHOW_NUMBERWHEEL_FOR_SHAPES @"SHOW_NUMBERWHEEL_FOR_SHAPES"
#define SHOW_COUNT_BUBBLE @"SHOW_COUNT_BUBBLE"
#define REQUIRED_SHAPES @"REQUIRED_SHAPES"
#define AUTO_UPDATE_WHEEL @"AUTO_UPDATE_WHEEL"
#define DOTGRID_EVAL_NONPROP_X @"DOTGRID_EVAL_NONPROP_X"
#define DOTGRID_EVAL_NONPROP_Y @"DOTGRID_EVAL_NONPROP_Y"


// long division tool

#define DIVIDEND @"DIVIDEND"
#define DIVISOR @"DIVISOR"
#define ROW_MULTIPLIER @"ROW_MULTIPLIER"
#define START_COLUMN_VALUE @"START_COLUMN_VALUE"
#define GOOD_BAD_HIGHLIGHT @"GOOD_BAD_HIGHLIGHT"
#define ROW_MULTIPLIER @"ROW_MULTIPLIER"
#define RENDERBLOCK_LABELS @"RENDERBLOCK_LABELS"
#define HIDE_RENDERLAYER @"HIDE_RENDERLAYER"
#define COLUMNS_IN_PICKER @"COLUMNS_IN_PICKER"
#define START_ROW @"START_ROW"

// times tables tool

#define SELECTION_MODE @"SELECTION_MODE"
#define SHOW_X_AXIS @"SHOW_X_AXIS"
#define SHOW_Y_AXIS @"SHOW_Y_AXIS"
#define ALLOW_X_HIGHLIGHT @"ALLOW_X_HIGHLIGHT"
#define ALLOW_Y_HIGHLIGHT @"ALLOW_Y_HIGHLIGHT"
#define SWITCH_XY_ANSWER @"SWITCH_XY_ANSWER"
#define ACTIVE_ROWS @"ACTIVE_ROWS"
#define ACTIVE_COLS @"ACTIVE_COLS"
#define HIGHLIGHT_ROWS @"HIGHLIGHT_ROWS"
#define HIGHLIGHT_COLS @"HIGHLIGHT_COLS"
#define SHOW_CALC_BUBBLE @"SHOW_CALC_BUBBLE"
#define REVEAL_ROWS @"REVEAL_ROWS"
#define REVEAL_COLS @"REVEAL_COLS"
#define REVEAL_TILES @"REVEAL_TILES"
#define REVEAL_ALL_TILES @"REVEAL_ALL_TILES"
#define SOLUTION_MODE @"SOLUTION_MODE"
#define SOLUTION_VALUE @"SOLUTION_VALUE"
#define SOLUTION_COMPONENT @"SOLUTION_COMPONENT"
#define DISABLED_TILES @"DISABLED_TILES"


// number picker
#define NUMBER_PICKER_DESCRIPTION @"NUMBER_PICKER_DESCRIPTION"
#define NUMBER_PICKER @"NUMBER_PICKER"
#define PICKER_LAYOUT @"PICKER_LAYOUT"
#define PICKER_ORIGIN_X @"PICKER_ORIGIN_X"
#define PICKER_ORIGIN_Y @"PICKER_ORIGIN_Y"
#define ANIMATE_FROM_PICKER @"ANIMATE_FROM_PICKER"
#define SHOW_DROPBOX @"SHOW_DROPBOX"
#define MAX_NUMBERS @"MAX_NUMBERS"
#define EVAL_VALUE @"EVAL_VALUE"
#define PICKER_EVAL_MODE @"PICKER_EVAL_MODE"
#define DISABLE_WHEEL @"DISABLE_WHEEL"
#define DISABLE_CALCULATOR @"DISABLE_CALCULATOR"


// pie splitter tool
#define NUMBER_CAGED_PIES @"NUMBER_CAGED_PIES"
#define NUMBER_CAGED_SQUARES @"NUMBER_CAGED_SQUARES"
#define NUMBER_ACTIVE_PIES @"NUMBER_ACTIVE_PIES"
#define NUMBER_ACTIVE_SQUARES @"NUMBER_ACTIVE_SQUARES"
#define SPLIT_WITH_CORRECT_NUMBERS @"SPLIT_WITH_CORRECT_NUMBERS"
#define START_PROBLEM_SPLIT @"START_PROBLEM_SPLIT"
#define SHOW_RESET_SLICES @"SHOW_RESET_SLICES"

//distribution tool
#define DISTRIBUTION_EVAL_TYPE @"DISTRIBUTION_EVAL_TYPE"
#define IS_EVAL_TARGET @"IS_EVAL_TARGET"
#define HAS_CAGE @"HAS_CAGE"
#define DOCK_TYPE @"DOCK_TYPE"
#define BLOCK_TYPE @"BLOCK_TYPE"
#define CAGE_OBJECT_COUNT @"CAGE_OBJECT_COUNT"
#define EVAL_AREAS @"EVAL_AREAS"
#define AREA_SIZE @"AREA_SIZE"
#define AREA_WIDTH @"AREA_WIDTH"
#define AREA_OPACITY @"AREA_OPACITY"
#define HAS_INACTIVE_AREA @"HAS_INACTIVE_AREA"
#define UNBREAKABLE_BONDS @"UNBREAKABLE_BONDS"
#define RANDOMISE_DOCK_POSITIONS @"RANDOMISE_DOCK_POSITIONS"
#define BOND_DIFFERENT_TYPES @"BOND_DIFFERENT_TYPES"
#define BOND_ALL_OBJECTS @"BOND_ALL_OBJECTS"
#define TINT_COLOUR @"TINT_COLOUR"
#define SHOW_TOTAL_VALUE @"SHOW_TOTAL_VALUE"
#define SHOW_CONTAINER_VALUE @"SHOW_CONTAINER_VALUE"
#define EVAL_CIRCLES_REQUIRED @"EVAL_CIRCLES_REQUIRED"
#define EVAL_DIAMONDS_REQUIRED @"EVAL_DIAMONDS_REQUIRED"
#define EVAL_ELLIPSES_REQUIRED @"EVAL_ELLIPSES_REQUIRED"
#define EVAL_HOUSES_REQUIRED @"EVAL_HOUSES_REQUIRED"
#define EVAL_ROUNDEDSQUARES_REQUIRED @"EVAL_ROUNDEDSQUARES_REQUIRED"
#define EVAL_SQUARES_REQUIRED @"EVAL_SQUARES_REQUIRED"
#define EVAL_VALUE_001_REQUIRED @"EVAL_VALUE_001_REQUIRED"
#define EVAL_VALUE_01_REQUIRED @"EVAL_VALUE_01_REQUIRED"
#define EVAL_VALUE_1_REQUIRED @"EVAL_VALUE_1_REQUIRED"
#define EVAL_VALUE_10_REQUIRED @"EVAL_VALUE_10_REQUIRED"
#define EVAL_VALUE_100_REQUIRED @"EVAL_VALUE_100_REQUIRED"

//fraction builder
#define INIT_FRACTIONS @"INIT_FRACTIONS"
#define FRACTION_MODE @"FRACTION_MODE"
#define MARKER_START_POSITION @"MARKER_START_POSITION"
#define VALUE @"VALUE"
#define CREATE_CHUNKS_ON_INIT @"CREATE_CHUNKS_ON_INIT"
#define SHOW_EQUIVALENT_FRACTIONS @"SHOW_EQUIVALENT_FRACTIONS"
#define START_HIDDEN @"START_HIDDEN"
#define SHOW_CURRENT_FRACTIONS @"SHOW_CURRENT_FRACTIONS"
#define SOLUTION_DIVIDEND @"SOLUTION_DIVIDEND"
#define SOLUTION_DIVISOR @"SOLUTION_DIVISOR"
#define SOLUTION_EVAL_FRACTION_TAG @"SOLUTION_EVAL_FRACTION_TAG"



// counting timer
#define COUNT_MAX @"COUNT_MAX"
#define COUNT_MIN @"COUNT_MIN"
#define USE_NUMICON_NUMBERS @"USE_NUMICON_NUMBERS"
#define USE_NUMICON_NUMBER @"USE_NUMICON_NUMBER"
#define NUMICON_FLASH @"NUMICON_FLASH"
#define COUNT_TYPE @"COUNT_TYPE"
#define DISPLAY_COUNT @"DISPLAY_COUNT"
#define INCREMENT @"INCREMENT"
#define FLASHING_BUTTON @"FLASHING_BUTTON"

// floating block
#define INIT_BUBBLES @"INIT_BUBBLES"
#define BUBBLE_AUTO_OPERATE @"BUBBLE_AUTO_OPERATE"
#define MAX_GROUP_SIZE @"MAX_GROUP_SIZE"
#define MIN_BLOCKS_FROM_PIPE @"MIN_BLOCKS_FROM_PIPE"
#define MAX_BLOCKS_FROM_PIPE @"MAX_BLOCKS_FROM_PIPE"
#define DEFAULT_BLOCKS_FROM_PIPE @"DEFAULT_BLOCKS_FROM_PIPE"
#define SHOW_MULTIPLE_CONTROLS @"SHOW_MULTIPLE_CONTROLS"
#define SHOW_SOLUTION_ON_PIPE @"SHOW_SOLUTION_ON_PIPE"
#define SUPPORTED_OPERATORS @"SUPPORTED_OPERATORS"
#define SHOW_INPUT_PIPE @"SHOW_INPUT_PIPE"

// MQ Display Tool
#define DISPLAY @"DISPLAY"
#define STRING @"STRING"

// ratio tool
#define INIT_VALUE_RED @"INIT_VALUE_RED"
#define INIT_VALUE_BLUE @"INIT_VALUE_BLUE"
#define INIT_VALUE_GREEN @"INIT_VALUE_GREEN"
#define EVAL_VALUE_RED @"EVAL_VALUE_RED"
#define EVAL_VALUE_BLUE @"EVAL_VALUE_BLUE"
#define EVAL_VALUE_GREEN @"EVAL_VALUE_GREEN"
#define WHEEL_MAX @"WHEEL_MAX"
#define RECIPE_RED @"RECIPE_RED"
#define RECIPE_GREEN @"RECIPE_GREEN"
#define RECIPE_BLUE @"RECIPE_BLUE"

//journey scene
#define REGION_ZOOM_LEVEL 0.15f

#define ISLAND_MASTERY @"ISLAND_MASTERY"
#define ISLAND_NODES @"ISLAND_NODES"
#define ISLAND_LABEL_POS @"ISLAND_LABEL"
#define ISLAND_LABEL_ROT @"ISLAND_ROT"
#define ISLAND_FEATURE_SPACES @"ISLAND_FEATURE_SPACES"
#define ISLAND_POS @"ISLAND_POS"
#define ISLAND_RADIUS @"ISLAND_RADIUS"

#define FIXED_SIZE_Y 768
#define FIXED_SIZE_X 1024


//btxe
#define BTXE_HPAD 9.0f
#define BTXE_VPAD 9.0f
#define BTXE_OTBKG_SPRITE_W 8.0f
#define BTXE_OTBKG_SPRITE_H 38.0f
#define BTXE_OTBKG_WIDTH_OVERDRAW_PAD 30.0f
#define BTXE_PICKUP_PROXIMITY 25.0f
#define BTXE_ROW_DEFAULT_MAX_WIDTH 924.0f
#define BTXE_NAMESPACE @"http://zubi.me/namespaces/2012/BTXE"
#define BTXE_T @"b:t"
#define BTXE_BR @"b:br"
#define BTXE_OT @"b:ot"
#define BTXE_OI @"b:oi"
#define BTXE_ON @"b:on"
#define BTXE_OO @"b:oo"
#define BTXE_PH @"b:ph"
#define BTXE_OBJ @"b:obj"
#define BTXE_COMMOT @"b:commot"


#define QUESTION_SEPARATOR_PADDING 20.0f


//scoring
#define SCORE_EPISODE_MAX 999999.0f
#define SCORE_STAGE_CAP 5
#define SCORE_STAGE_MULTIPLIER 2
#define SCORE_MAX_SHARDS 180
#define SCORE_ARTIFACT_1 0
#define SCORE_ARTIFACT_2 499999
#define SCORE_ARTIFACT_3 999998             
#define SCORE_ARTIFACT_4 999998
#define SCORE_ARTIFACT_5 999998

// Logging:

#define CODE_LOCATION() [NSString stringWithFormat:@"<%@:%@:%d>", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__]

#define BL_APP_START @"APP_START"
#define BL_APP_RESIGN_ACTIVE @"APP_RESIGN_ACTIVE"
#define BL_APP_BECOME_ACTIVE @"APP_BECOME_ACTIVE"
#define BL_APP_ENTER_BACKGROUND @"APP_ENTER_BACKGROUND"
#define BL_APP_ENTER_FOREGROUND @"APP_ENTER_FOREGROUND"
#define BL_APP_ABANDON @"APP_ABANDON"
#define BL_APP_MEMORY_WARNING @"APP_MEMORY_WARNING"

#define BL_APP_ERROR @"APP_ERROR"

#define BL_APP_ERROR_TYPE_FAIL_QUEUE_BATCH @"FAIL_QUEUE_BATCH"
#define BL_APP_ERROR_TYPE_FAIL_REQUEUE_BATCH @"FAIL_REQUEUE_BATCH"
#define BL_APP_ERROR_TYPE_BAD_ARG @"BAD_ARG"
#define BL_APP_ERROR_TYPE_MISSING_PDEF @"MISSING_PDEF"
#define BL_APP_ERROR_TYPE_UNEXPECTED_NULL_VALUE @"UNEXPECTED_NULL_VALUE"
#define BL_APP_ERROR_TYPE_DB_TABLE_MISSING_ROW @"DB_TABLE_MISSING_ROW"
#define BL_APP_ERROR_TYPE_DB_OPERATION_FAILURE @"DB_OPERATION_FAILURE"
#define BL_APP_ERROR_TYPE_CRASH @"APP_CRASH"
#define BL_APP_ERROR_TYPE_SQL @"SQL_ERROR"

#define BL_APP_FLAG_REMOVE_USER @"APP_FLAG_REMOVE_USER"
#define BL_APP_REMOVE_USERS @"APP_REMOVE_USERS"

#define BL_SUVC_LOAD @"SELECT_USER_VIEW_CONTROLLER_LOAD"

#define BL_USER_LOGIN @"USER_LOGIN"
#define BL_USER_LOGOUT @"USER_LOGOUT"
#define BL_USER_ENCOUNTER_FEATURE_KEY @"USER_ENCOUNTER_FEATURE_KEY"

#define BL_JS_INIT @"JOURNEY_SCENE_INIT"
#define BL_JS_PIN_SELECT @"JOURNEY_SCENE_PIN_SELECT"
#define BL_JS_ZOOM_OUT @"JOURNEY_SCENE_ZOOM_OUT"
#define BL_JS_ZOOM_IN @"JOURNEY_SCENE_ZOOM_IN"

#define BL_EP_START @"EPISODE_START"
#define BL_EP_ATTEMPT_ADAPT_PIPELINE_INSERTION @"EPISODE_ATTEMPT_ADAPT_PIPELINE_INSERTION"
#define BL_EP_PROBLEM_INSERT @"EPISODE_PROBLEM_INSERT"
#define BL_EP_PROBLEM_INSERT_TYPE_NEXT @"NEXT"
#define BL_EP_PROBLEM_INSERT_TYPE_ADAPT_VIABLE_INSERT @"ADAPT_VIABLE_INSERT"
#define BL_EP_PROBLEM_INSERT_TYPE_REPEAT_CURRENT_PROBLEM @"ADAPT_REPEAT_CURRENT_PROBLEM"
#define BL_EP_END @"EPISODE_END"

#define BL_PA_START @"PROBLEM_ATTEMPT_START"
#define BL_PA_PAUSE @"PROBLEM_ATTEMPT_USER_PAUSE"
#define BL_PA_RESUME @"PROBLEM_ATTEMPT_USER_RESUME"
#define BL_PA_SUCCESS @"PROBLEM_ATTEMPT_SUCCESS"
#define BL_PA_EXIT_TO_MAP @"PROBLEM_ATTEMPT_EXIT_TO_MAP"
#define BL_PA_USER_RESET @"PROBLEM_ATTEMPT_USER_RESET"
#define BL_PA_SKIP @"PROBLEM_ATTEMPT_SKIP"
#define BL_PA_SKIP_WITH_SUGGESTION @"PROBLEM_ATTEMPT_SKIP_WITH_SUGGESTION"
#define BL_PA_SKIP_DEBUG @"PROBLEM_ATTEMPT_SKIP_DEBUG"
#define BL_PA_FAIL @"PROBLEM_ATTEMPT_FAIL"
#define BL_PA_FAIL_WITH_CHILD_PROBLEM @"PROBLEM_ATTEMPT_FAIL_WITH_CHILD_PROBLEM"
#define BL_PA_USER_COMMIT @"PROBLEM_ATTEMPT_USER_COMMIT"
#define BL_PA_POSTPONE_FOR_INTRO_PROBLEM @"BL_PA_POSTPONE_FOR_INTRO_PROBLEM"

#define BL_PA_TH_PINCH @"PROBLEM_ATTEMPT_TOOLHOST_PINCH"

#define BL_PA_NP_NUMBER_FROM_PICKER @"PROBLEM_ATTEMPT_NUMBERPICKER_NUMBER_FROM_PICKER"
#define BL_PA_NP_NUMBER_FROM_REGISTER @"PROBLEM_ATTEMPT_NUMBERPICKER_NUMBER_FROM_REGISTER"
#define BL_PA_NP_NUMBER_MOVE @"PROBLEM_ATTEMPT_NUMBERPICKER_NUMBER_MOVE"
#define BL_PA_NP_NUMBER_DELETE @"PROBLEM_ATTEMPT_NUMBERPICKER_NUMBER_DELETE"

#define BL_PA_MQ_CHANGE_ANSWER @"PROBLEM_ATTEMPT_METAQUESTION_CHANGE_ANSWER"

#define BL_PA_NB_TOUCH_BEGIN_ON_CAGED_OBJECT @"PROBLEM_ATTEMPT_NUMBERBONDS_TOUCH_BEGIN_ON_CAGED_OBJECT"
#define BL_PA_NB_TOUCH_MOVE_MOVE_BLOCK @"PROBLEM_ATTEMPT_NUMBERBONDS_TOUCH_MOVE_MOVE_BLOCK"
#define BL_PA_NB_TOUCH_BEGIN_ON_ROW @"PROBLEM_ATTEMPT_NUMBERBONDS_TOUCH_BEGIN_ON_ROW"
#define BL_PA_NB_TOUCH_END_ON_ROW @"PROBLEM_ATTEMPT_NUMBERBONDS_TOUCH_END_ON_ROW"
#define BL_PA_NB_TOUCH_END_IN_SPACE @"PROBLEM_ATTEMPT_NUMBERBONDS_TOUCH_END_IN_SPACE"
#define BL_PA_NB_TOUCH_BEGIN_ON_LOCKED_ROW @"PROBLEM_ATTEMPT_NUMBERBONDS_TOUCH_BEGIN_ON_LOCKED_ROW"

#define BL_PA_DG_TOUCH_BEGIN_CREATE_SHAPE @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_BEGIN_CREATE_SHAPE"
#define BL_PA_DG_TOUCH_END_CREATE_SHAPE @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_END_CREATE_SHAPE"
#define BL_PA_DG_TOUCH_BEGIN_RESIZE_SHAPE @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_BEGIN_RESIZE_SHAPE"
#define BL_PA_DG_TOUCH_END_RESIZE_SHAPE @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_END_RESIZE_SHAPE"
#define BL_PA_DG_TOUCH_BEGIN_SELECT_TILE @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_BEGIN_SELECT_TILE"
#define BL_PA_DG_TOUCH_BEGIN_DESELECT_TILE @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_BEGIN_DESELECT_TILE"
#define BL_PA_DG_TOUCH_END_INVALID_RESIZE_HIDDEN @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_END_INVALID_RESIZE_HIDDEN"
#define BL_PA_DG_TOUCH_END_INVALID_RESIZE_EXISTING_TILE @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_END_INVALID_RESIZE_EXISTING_TILE"
#define BL_PA_DG_TOUCH_END_INVALID_CREATE_HIDDEN @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_END_INVALID_CREATE_HIDDEN"
#define BL_PA_DG_TOUCH_END_INVALID_CREATE_EXISTING_TILE @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_END_INVALID_CREATE_EXISTING_TILE"


#define BL_PA_LD_TOUCH_END_CHANGE_WHEEL_VALUE @"PROBLEM_ATTEMPT_LONGDIVISION_TOUCH_END_CHANGE_WHEEL_VALUE"

#define BL_PA_TT_TOUCH_BEGIN_HIGHLIGHT_ROW @"PROBLEM_ATTEMPT_TIMESTABLES_TOUCH_BEGIN_HIGHLIGHT_ROW"
#define BL_PA_TT_TOUCH_BEGIN_HIGHLIGHT_COLUMN @"PROBLEM_ATTEMPT_TIMESTABLES_TOUCH_BEGIN_HIGHLIGHT_COLUMN"
#define BL_PA_TT_TOUCH_BEGIN_UNHIGHLIGHT_ROW @"PROBLEM_ATTEMPT_TIMESTABLES_TOUCH_BEGIN_UNHIGHLIGHT_ROW"
#define BL_PA_TT_TOUCH_BEGIN_UNHIGHLIGHT_COLUMN @"PROBLEM_ATTEMPT_TIMESTABLES_TOUCH_BEGIN_UNHIGHLIGHT_COLUMN"
#define BL_PA_TT_TOUCH_BEGIN_REVEAL_ANSWER @"PROBLEM_ATTEMPT_TIMESTABLES_TOUCH_BEGIN_REVEAL_ANSWER"
#define BL_PA_TT_TOUCH_BEGIN_SELECT_ANSWER @"PROBLEM_ATTEMPT_TIMESTABLES_TOUCH_BEGIN_SELECT_ANSWER"
#define BL_PA_TT_TOUCH_BEGIN_DESELECT_ANSWER @"PROBLEM_ATTEMPT_TIMESTABLES_TOUCH_BEGIN_DESELECT_ANSWER"
#define BL_PA_TT_TOUCH_BEGIN_TAP_DISABLED_BOX @"PROBLEM_ATTEMPT_TIMESTABLES_TOUCH_BEGIN_TAP_DISABLED_BOX"

#define BL_PA_NL_TOUCH_BEGIN_PICKUP_BUBBLE @"PROBLEM_ATTEMPT_NUMBERLINE_TOUCH_BEGIN_PICKUP_BUBBLE"
#define BL_PA_NL_TOUCH_END_RELEASE_BUBBLE @"PROBLEM_ATTEMPT_NUMBERLINE_TOUCH_END_RELEASE_BUBBLE"
#define BL_PA_NL_TOUCH_MOVE_MOVE_BUBBLE @"PROBLEM_ATTEMPT_NUMBERLINE_TOUCH_MOVE_MOVE_BUBBLE"
#define BL_PA_NL_TOUCH_END_INCREASE_SELECTION @"PROBLEM_ATTEMPT_NUMBERLINE_TOUCH_END_INCREASE_SELECTION"
#define BL_PA_NL_TOUCH_END_DECREASE_SELECTION @"PROBLEM_ATTEMPT_NUMBERLINE_TOUCH_END_DECREASE_SELECTION"
#define BL_PA_NL_TOUCH_MOVE_MOVE_LINE @"PROBLEM_ATTEMPT_NUMBERLINE_TOUCH_MOVE_MOVE_LINE"
#define BL_PA_NL_TOUCH_END_JUMP_LINE @"PROBLEM_ATTEMPT_NUMBERLINE_TOUCH_END_JUMP_LINE"

#define BL_PA_PV_TOUCH_BEGIN_PICKUP_CAGE_OBJECT @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_BEGIN_PICKUP_CAGE_OBJECT"
#define BL_PA_PV_TOUCH_BEGIN_PICKUP_GRID_OBJECT @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_BEGIN_PICKUP_GRID_OBJECT"
#define BL_PA_PV_TOUCH_END_DROP_OBJECT_ON_CAGE @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_END_DROP_OBJECT_ON_CAGE"
#define BL_PA_PV_TOUCH_END_DROP_OBJECT_ON_GRID @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_END_DROP_OBJECT_ON_GRID"
#define BL_PA_PV_TOUCH_END_DROP_ZERO @"BL_PA_PLACEVALUE_TOUCH_END_DROP_ZERO"
#define BL_PA_PV_TOUCH_END_MULTIPLE_BLOCKS_NOT_ENOUGH_SPACE @"BL_PA_PLACEVALUE_TOUCH_END_MULTIPLE_BLOCKS_NOT_ENOUGH_SPACE"
#define BL_PA_PV_TOUCH_END_MULTIPLE_BLOCKS_DROPPED @"BL_PA_PLACEVALUE_TOUCH_END_MULTIPLE_BLOCKS_DROPPED"
#define BL_PA_PV_TOUCH_END_EXPLODE_BLOCKS @"BL_PA_PLACEVALUE_TOUCH_END_EXPLODE_BLOCKS"
#define BL_PA_PV_TOUCH_END_CONDENSE_OBJECT @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_END_CONDENSE_OBJECT"
#define BL_PA_PV_TOUCH_END_MULCH_OBJECTS @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_END_MULCH_OBJECTS"
#define BL_PA_PV_TOUCH_MOVE_MOVE_OBJECT @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_MOVE_MOVE_OBJECT"
#define BL_PA_PV_TOUCH_MOVE_MOVE_OBJECTS @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_MOVE_MOVE_OBJECTS"
#define BL_PA_PV_TOUCH_BEGIN_SELECT_OBJECT @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_BEGIN_SELECT_OBJECT"
#define BL_PA_PV_TOUCH_BEGIN_DESELECT_OBJECT @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_BEGIN_DESELECT_OBJECT"
#define BL_PA_PV_TOUCH_BEGIN_COUNT_OBJECT @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_BEGIN_COUNT_OBJECT"
#define BL_PA_PV_TOUCH_BEGIN_UNCOUNT_OBJECT @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_BEGIN_UNCOUNT_OBJECT"
#define BL_PA_PV_TOUCH_MOVE_MOVE_GRID @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_MOVE_MOVE_GRID"
#define BL_PA_PV_TOUCH_END_BLOCKSTOCREATE_UP @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_END_BLOCKSTOCREATE_UP"
#define BL_PA_PV_TOUCH_END_BLOCKSTOCREATE_DOWN @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_END_BLOCKSTOCREATE_DOWN"
#define BL_PA_PV_TOUCH_MOVE_MOVED_TO_DISABLED_CAGE @"BL_PA_PLACEVALUE_TOUCH_MOVE_MOVED_TO_DISABLED_CAGE"
#define BL_PA_PV_TOUCH_END_DROPPED_BASE_PICKUP_ON_NET @"BL_PA_PLACEVALUE_TOUCH_END_DROPPED_BASE_PICKUP_ON_NET"
#define BL_PA_PV_TOUCH_END_DROPPED_BASE_PICKUP_ON_CAGE @"BL_PA_PLACEVALUE_TOUCH_END_DROPPED_BASE_PICKUP_ON_CAGE"


#define BL_PA_FB_TOUCH_BEGIN_PICKUP_CHUNK @"PROBLEM_ATTEMPT_FRACTIONBUILDER_TOUCH_BEGIN_PICKUP_CHUNK"
#define BL_PA_FB_TOUCH_MOVE_MOVE_CHUNK @"PROBLEM_ATTEMPT_FRACTIONBUILDER_TOUCH_MOVE_MOVE_CHUNK"
#define BL_PA_FB_TOUCH_MOVE_MOVE_MARKER @"PROBLEM_ATTEMPT_FRACTIONBUILDER_TOUCH_MOVE_MOVE_MARKER"
#define BL_PA_FB_MOUNT_TO_FRACTION @"PROBLEM_ATTEMPT_FRACTIONBUILDER_MOUNT_TO_FRACTION"
#define BL_PA_FB_CREATE_CHUNKS @"PROBLEM_ATTEMPT_FRACTIONBUILDER_CREATE_CHUNKS"
#define BL_PA_FB_FAILED_EVAL_ADDITION @"PROBLEM_ATTEMPT_FRACTIONBUILDER_FAILED_EVAL_ADDITION"
#define BL_PA_FB_FAILED_EVAL_EQUIVALENT @"PROBLEM_ATTEMPT_FRACTIONBUILDER_FAILED_EVAL_EQUIVALENT"

#define BL_PA_PS_TOUCH_BEGIN_TOUCH_CAGED_PIE @"PROBLEM_ATTEMPT_PIESPLITTER_TOUCH_BEGIN_TOUCH_CAGED_PIE"
#define BL_PA_PS_TOUCH_BEGIN_TOUCH_CAGED_SQUARE @"PROBLEM_ATTEMPT_PIESPLITTER_TOUCH_BEGIN_TOUCH_CAGED_SQUARE"
#define BL_PA_PS_TOUCH_MOVE_MOVE_PIE @"PROBLEM_ATTEMPT_PIESPLITTER_TOUCH_MOVE_MOVE_PIE"
#define BL_PA_PS_TOUCH_MOVE_MOVE_SQUARE @"PROBLEM_ATTEMPT_PIESPLITTER_TOUCH_MOVE_MOVE_SQUARE"
#define BL_PA_PS_TOUCH_END_RETURN_CAGED_PIE @"PROBLEM_ATTEMPT_PIESPLITTER_TOUCH_END_RETURN_CAGED_PIE"
#define BL_PA_PS_TOUCH_END_RETURN_CAGED_SQUARE @"PROBLEM_ATTEMPT_PIESPLITTER_TOUCH_END_RETURN_CAGED_SQUARE"
#define BL_PA_PS_TOUCH_END_MOUNT_CAGED_PIE @"PROBLEM_ATTEMPT_PIESPLITTER_TOUCH_END_MOUNT_CAGED_PIE"
#define BL_PA_PS_TOUCH_END_MOUNT_CAGED_SQUARE @"PROBLEM_ATTEMPT_PIESPLITTER_TOUCH_END_MOUNT_CAGED_SQUARE"
#define BL_PA_PS_SPLIT_PIE @"PROBLEM_ATTEMPT_PIESPLITTER_SPLIT_PIE"
#define BL_PA_PS_RETURN_SLICES_TO_PIE @"PROBLEM_ATTEMPT_PIESPLITTER_RETURN_SLICES_TO_PIE"
#define BL_PA_PS_TOUCH_BEGIN_TOUCH_MOUNTED_PIE @"PROBLEM_ATTEMPT_PIESPLITTER_TOUCH_BEGIN_TOUCH_MOUNTED_PIE"
#define BL_PA_PS_TOUCH_BEGIN_TOUCH_MOUNTED_SQUARE @"PROBLEM_ATTEMPT_PIESPLITTER_TOUCH_BEGIN_TOUCH_MOUNTED_SQUARE"
#define BL_PA_PS_TOUCH_MOVE_MOVE_SLICE @"PROBLEM_ATTEMPT_PIESPLITTER_TOUCH_MOVE_MOVE_SLICE"
#define BL_PA_PS_TOUCH_END_MOUNT_SLICE_TO_PIE @"PROBLEM_ATTEMPT_PIESPLITTER_TOUCH_END_MOUNT_SLICE_TO_PIE"
#define BL_PA_PS_TOUCH_END_MOUNT_SLICE_TO_SQUARE @"PROBLEM_ATTEMPT_PIESPLITTER_TOUCH_END_MOUNT_SLICE_TO_SQUARE"

#define BL_PA_DT_TOUCH_START_PICKUP_BLOCK @"PROBLEM_ATTEMPT_DISTRIBUTIONTOOL_TOUCH_START_PICKUP_BLOCK"
#define BL_PA_DT_TOUCH_MOVE_MOVE_BLOCK @"PROBLEM_ATTEMPT_DISTRIBUTIONTOOL_TOUCH_MOVE_MOVE_BLOCK"
#define BL_PA_DT_TOUCH_END_PAIR_BLOCK @"PROBLEM_ATTEMPT_DISTRIBUTIONTOOL_TOUCH_END_PAIR_BLOCK"
#define BL_PA_DT_TOUCH_MOVE_PROXIMITY_OF_BLOCK @"PROBLEM_ATTEMPT_DISTRIBUTIONTOOL_TOUCH_MOVE_PROXIMITY_OF_BLOCK"

#define BL_PA_CT_TOUCH_START_START_TIMER @"BL_PA_COUNTINGTIMER_TOUCH_START_START_TIMER"
#define BL_PA_CT_TOUCH_START_STOP_TIMER @"BL_PA_COUNTINGTIMER_TOUCH_START_STOP_TIMER"
#define BL_PA_CT_TIMER_EXPIRED @"BL_PA_COUNTINGTIMER_TIMER_EXPIRED"

#define BL_PA_FBLOCK_TOUCH_START_PICKUP_GROUP @"BL_PA_FLOATINGBLOCK_TOUCH_START_PICKUP_GROUP"
#define BL_PA_FBLOCK_TOUCH_MOVE_MOVE_GROUP @"BL_PA_FLOATINGBLOCK_TOUCH_MOVE_MOVE_GROUP"
#define BL_PA_FBLOCK_TOUCH_MOVE_PLACE_GROUP_IN_BUBBLE @"BL_PA_FLOATINGBLOCK_TOUCH_MOVE_PLACE_GROUP_IN_BUBBLE"
#define BL_PA_FBLOCK_TOUCH_MOVE_PLACE_GROUP_IN_FREE_SPACE @"BL_PA_FLOATINGBLOCK_TOUCH_MOVE_PLACE_GROUP_IN_FREE_SPACE"
#define BL_PA_FBLOCK_TOUCH_END_SHOW_MORE_OPERATORS @"BL_PA_FLOATINGBLOCK_TOUCH_END_SHOW_MORE_OPERATORS"
#define BL_PA_FBLOCK_TOUCH_END_USE_OPERATOR @"BL_PA_FLOATINGBLOCK_TOUCH_END_USE_OPERATOR"
#define BL_PA_FBLOCK_TOUCH_END_CHANGE_NUMBER_WHEEL @"BL_PA_FLOATINGBLOCK_TOUCH_END_CHANGE_NUMBER_WHEEL"
#define BL_PA_FBLOCK_TOUCH_END_DROP_OBJECT_PIPE @"BL_PA_FLOATINGBLOCK_TOUCH_END_DROP_OBJECT_PIPE"
#define BL_PA_FBLOCK_TOUCH_START_CREATE_NEW_GROUP @"BL_PA_FLOATINGBLOCK_TOUCH_START_CREATE_NEW_GROUP"

#define BL_PA_EXPRBUILDER_TOUCH_START_PICKUP_CARD @"BL_PA_EXPRBUILDER_TOUCH_START_PICKUP_CARD"
#define BL_PA_EXPRBUILDER_TOUCH_END_DROP_CARD_EMPTY_SPACE @"BL_PA_EXPRBUILDER_TOUCH_END_DROP_CARD_EMPTY_SPACE"
#define BL_PA_EXPRBUILDER_TOUCH_END_DROP_CARD_PLACEHOLDER @"BL_PA_EXPRBUILDER_TOUCH_END_DROP_CARD_PLACEHOLDER"
#define BL_PA_EXPRBUILDER_TOUCH_MOVE_MOVED_CARD @"BL_PA_EXPRBUILDER_TOUCH_MOVE_MOVED_CARD"
#define BL_PA_EXPRBUILDER_TOUCH_START_START_PICKER @"BL_PA_EXPRBUILDER_TOUCH_START_START_PICKER"
#define BL_PA_EXPRBUILDER_TOUCH_MOVE_CHANGE_PICKER @"BL_PA_EXPRBUILDER_TOUCH_MOVE_CHANGE_PICKER"
#define BL_PA_EXPRBUILDER_TOUCH_START_HIDE_PICKER @"BL_PA_EXPRBUILDER_TOUCH_START_HIDE_PICKER"




#define BL_PA_RT_TOUCH_END_CHANGED_RED @"BL_PA_RATIOTOOL_TOUCH_END_CHANGED_RED"
#define BL_PA_RT_TOUCH_END_CHANGED_GREEN @"BL_PA_RATIOTOOL_TOUCH_END_CHANGED_GREEN"
#define BL_PA_RT_TOUCH_END_CHANGED_BLUE @"BL_PA_RATIOTOOL_TOUCH_END_CHANGED_BLUE"

