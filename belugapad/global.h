//
//  global.h
//  belugapad
//
//  Created by Gareth Jenkins on 03/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define BUNDLE_FULL_PATH(_filePath_) [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:_filePath_]

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


#define MOUNT @"MOUNT"
#define MOUNTED_OBJECT @"MOUNTED_OBJECT"
#define MOUNTED_OBJECTS @"MOUNTED_OBJECTS"
#define DISABLED @"DISABLED"

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
#define EVAL_MODE @"EVAL_MODE"
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

// PlaceValue specifics

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
#define COUNT_SEQUENCE @"COUNT_SEQUENCE"
#define TOTAL_COUNT @"TOTAL_COUNT"
#define TOTAL_COUNT_AND_COUNT_SEQUENCE @"TOTAL_COUNT_AND_COUNT_SEQUENCE"
#define MATRIX_MATCH @"MATRIX_MATCH"
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

// BlockFloating specifics

#define SEPARATOR_FILENAME @"SEPARATOR_FILENAME"
#define OBJECT_OVERLAY_FILENAME @"OBJECT_OVERLAY_FILENAME"


#define TUTORIALS @"TUTORIALS"
#define GHOST_OBJECT @"GHOST_OBJECT"
#define GHOST_DESTINATION @"GHOST_DESTINATION"
#define ENABLE_CONTAINERS @"ENABLE_CONTAINERS"
#define ENABLE_OCCLUDING_SEPARATORS @"ENABLE_OCCLUDING_SEPARATORS"

#define PRE_ACTIONS @"PRE_ACTIONS"
#define POST_ACTIONS @"POST_ACTIONS"

#define SOLUTION_DISPLAY_TEXT @"SOLUTION_DISPLAY_TEXT"
#define INCOMPLETE_DISPLAY_TEXT @"INCOMPLETE_DISPLAY_TEXT"
#define PLAY_SOUND @"PLAY_SOUND"

#define OPERATOR_MODE @"OPERATOR_MODE"

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

// dotgrid tool

#define DRAW_MODE @"DRAW_MODE"
#define ANCHOR_SPACE @"ANCHOR_SPACE"
#define START_X @"START_X"
#define START_Y @"START_Y"
#define END_X @"END_X"
#define END_Y @"END_Y"
#define SHOW_MOVE @"SHOW_MOVE"
#define SHOW_RESIZE @"SHOW_RESIZE"
#define HIDDEN_ROWS @"HIDDEN_ROWS"