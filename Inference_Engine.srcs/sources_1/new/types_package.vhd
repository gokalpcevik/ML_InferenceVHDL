library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.fixed_pkg.all;

package types is
    constant FP_INTEGER_BITS:    INTEGER := 2;
    constant FP_FRACTIONAL_BITS: INTEGER := 15;
    constant FP_TOTAL_WIDTH:     INTEGER := FP_INTEGER_BITS + FP_FRACTIONAL_BITS + 1;
    
    constant FP_MUL_LEFT_INDEX:  INTEGER := 2 * FP_INTEGER_BITS + 1;
    constant FP_MUL_RIGHT_INDEX: INTEGER := -2 * FP_FRACTIONAL_BITS;
    
    constant FP_ADD_LEFT_INDEX:  INTEGER := FP_INTEGER_BITS + 1;
    constant FP_ADD_RIGHT_INDEX: INTEGER := -FP_FRACTIONAL_BITS;
    
    /**********************************
     **CFD MODEL SPECIFIC DEFINITIONS**
     **********************************/
    constant CFD_MODEL_INPUT_WIDTH: INTEGER := 8;
    constant CFD_MODEL_L1_NUM_NEURONS: INTEGER := 15;
    constant CFD_MODEL_L2_NUM_NEURONS: INTEGER := 15;
    constant CFD_MODEL_L3_NUM_NEURONS: INTEGER := 4;
    
    -- ! Crashes Vivado XSim if used within vectors or matrices
    subtype fixed_t is sfixed(FP_INTEGER_BITS downto -FP_FRACTIONAL_BITS);
    
    type fixed_vector_t is array(natural range <>) of sfixed(FP_INTEGER_BITS downto -FP_FRACTIONAL_BITS);
    type fixed_matrix_t is array(natural range <>,natural range <>) of sfixed(FP_INTEGER_BITS downto -FP_FRACTIONAL_BITS);

    type fixed_mul_vector_t is array(natural range<>) of sfixed(FP_MUL_LEFT_INDEX downto FP_MUL_RIGHT_INDEX);
    type fixed_add_vector_t is array(natural range<>) of sfixed(FP_ADD_LEFT_INDEX downto FP_ADD_RIGHT_INDEX);

    type activation_t is (ReLU, Linear);
    function to_fixed_t(q: real) return sfixed;
    function to_fixed_mul_t(q: real) return sfixed;

    function clog2 (A : NATURAL) return INTEGER;

end package;

package body types is
    function to_fixed_t(q: real) return sfixed is
    begin 
        return to_sfixed(q,FP_INTEGER_BITS, -FP_FRACTIONAL_BITS);
    end;

    function to_fixed_mul_t(q: real) return sfixed is
    begin 
        return to_sfixed(q, FP_MUL_LEFT_INDEX, FP_MUL_RIGHT_INDEX);
    end;

    -- * Borrowed from IEEE package float_generic
    function clog2(A: natural) return INTEGER is
        variable Y : REAL;
        variable N : INTEGER := 0;
    begin
    if  A = 1 or A = 0 then  -- trivial rejection and acceptance
        return A;
    end if;
    Y := real(A);
    while Y >= 2.0 loop
        Y := Y / 2.0;
        N := N + 1;
    end loop;
    if Y > 0.0 then
        N := N + 1;  -- round up to the nearest log2
    end if;
    return N;

    end function clog2;
end types;