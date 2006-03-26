(*
  Game of Live implementation in OCaml

  March 2006, Martijn Vermaat

  Ideas/todo:
  * only evolve cells that have potential to live (living cells and their
    neighbours)
  * automatic constant evolving
  * storing and loading of figures
  * have position (0,0) in center for easier storing of figures
  * connect left/right and top/bottom edges of world
  * evolving of world should maybe be done in world.ml
*)


open Graphics
open World


(*
  Configuration.
  A board of 50x50 is reasonable, with fields 10x10.
*)
let board_width, board_height = 50, 50
and field_width, field_height = 10, 10
and dead_color                = black
and living_color              = blue


(*
  Redraw all cells in given changeset on the board. Use double buffering to
  prevent the board from flickering (turn of graphics auto synchronization).
*)
let draw_changeset changeset =
  let fill_cell (x, y) color =
    set_color color;
    let x' = x * field_width and y' = y * field_height in
      fill_rect x' y' (field_width - 1) (field_height - 1)
  in
  let draw_cell = function
      Living, pos -> fill_cell pos living_color
    | Dead, pos   -> fill_cell pos dead_color
  in
    auto_synchronize false;
    List.iter draw_cell changeset;
    auto_synchronize true


(*
  Toggle state of the cell that we clicked and return the updated world.
*)
let click (x, y) world =
  ignore (wait_next_event [Button_up]);
  let pos = x/field_width, y/field_height in
    toggle_cell pos world


(*
  Calculate new state for each cell in the world and return the updated world.
*)
let evolve_world world =
  let evolve_cell cell =
    let state, pos = cell
    and n = num_neighbours cell world in
      match state, n with
          _,      3 -> Living, pos
        | Living, 2 -> Living, pos
        | _         -> Dead,   pos
  in
    world_map evolve_cell world


(*
  Main loop takes a world and waits for the user to do something. This can be
  a request to play a round of the game, update the state of a cell, etc. This
  is repeated with the possibly updated world.
  This function is tail-recursive so it should not perform worse than an
  imperative 'while true' loop.
  Exit is raised if the user wants to quit the game.
*)
let rec main world =
  let st = wait_next_event [Button_down; Key_pressed] in
  let next_world =
    begin
      if st.button then
        click (mouse_pos ()) world
      else if st.keypressed then
        match st.key with
            'q' -> raise Exit
          | ' ' -> evolve_world world
          | _   -> world
      else
        world
    end
  in
    draw_changeset (changeset world next_world);
    main next_world


(*
  Start by creating a new window for the board and call the main loop with an
  empty world.
*)
let () =
  open_graph (Printf.sprintf " %dx%d"
                (board_width * field_width)
                (board_height * field_height));
  set_window_title "Game of Life";
  set_color dead_color;
  fill_rect 0 0 (board_width * field_width) (board_height * field_height);
  try
    main (new_world board_width board_height)
  with
      Exit              -> exit 0
    | Graphic_failure _ -> exit 0   (* raised when closing the window *)