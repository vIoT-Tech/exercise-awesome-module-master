package pkg5 is
  type my_arr2D_t is array (0 to 1) of real_vector;

  constant my_arr2D: my_arr2D_t(open)(0 to 1) := (
    (0.0, 0.1),
    (1.0, 1.1)
  );
end;
