// Lean compiler output
// Module: lib
// Imports: public import Init public meta import Init
#include <lean/lean.h>
#if defined(__clang__)
#pragma clang diagnostic ignored "-Wunused-parameter"
#pragma clang diagnostic ignored "-Wunused-label"
#elif defined(__GNUC__) && !defined(__CLANG__)
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-label"
#pragma GCC diagnostic ignored "-Wunused-but-set-variable"
#endif
#ifdef __cplusplus
extern "C" {
#endif
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
lean_object* lean_nat_add(lean_object*, lean_object*);
uint64_t lean_uint64_mul(uint64_t, uint64_t);
uint64_t lean_uint64_add(uint64_t, uint64_t);
LEAN_EXPORT lean_object* l_fib(lean_object*);
LEAN_EXPORT lean_object* l_fib___boxed(lean_object*);
LEAN_EXPORT uint64_t l_add3(uint64_t);
LEAN_EXPORT lean_object* l_add3___boxed(lean_object*);
LEAN_EXPORT lean_object* l_doubleNat(lean_object*);
LEAN_EXPORT lean_object* l_doubleNat___boxed(lean_object*);
LEAN_EXPORT lean_object* l_fib(lean_object* v_x_1_){
_start:
{
lean_object* v_zero_2_; uint8_t v_isZero_3_; 
v_zero_2_ = lean_unsigned_to_nat(0u);
v_isZero_3_ = lean_nat_dec_eq(v_x_1_, v_zero_2_);
if (v_isZero_3_ == 1)
{
return v_zero_2_;
}
else
{
lean_object* v_one_4_; lean_object* v_n_5_; uint8_t v_isZero_6_; 
v_one_4_ = lean_unsigned_to_nat(1u);
v_n_5_ = lean_nat_sub(v_x_1_, v_one_4_);
v_isZero_6_ = lean_nat_dec_eq(v_n_5_, v_zero_2_);
if (v_isZero_6_ == 1)
{
lean_dec(v_n_5_);
return v_one_4_;
}
else
{
lean_object* v_n_7_; lean_object* v___x_8_; lean_object* v___x_9_; lean_object* v___x_10_; lean_object* v___x_11_; 
v_n_7_ = lean_nat_sub(v_n_5_, v_one_4_);
lean_dec(v_n_5_);
v___x_8_ = lean_nat_add(v_n_7_, v_one_4_);
v___x_9_ = l_fib(v___x_8_);
lean_dec(v___x_8_);
v___x_10_ = l_fib(v_n_7_);
lean_dec(v_n_7_);
v___x_11_ = lean_nat_add(v___x_9_, v___x_10_);
lean_dec(v___x_10_);
lean_dec(v___x_9_);
return v___x_11_;
}
}
}
}
LEAN_EXPORT lean_object* l_fib___boxed(lean_object* v_x_12_){
_start:
{
lean_object* v_res_13_; 
v_res_13_ = l_fib(v_x_12_);
lean_dec(v_x_12_);
return v_res_13_;
}
}
LEAN_EXPORT uint64_t l_add3(uint64_t v_x_14_){
_start:
{
uint64_t v___x_15_; uint64_t v___x_16_; uint64_t v___x_17_; uint64_t v___x_18_; 
v___x_15_ = 3ULL;
v___x_16_ = lean_uint64_mul(v_x_14_, v___x_15_);
v___x_17_ = 1ULL;
v___x_18_ = lean_uint64_add(v___x_16_, v___x_17_);
return v___x_18_;
}
}
LEAN_EXPORT lean_object* l_add3___boxed(lean_object* v_x_19_){
_start:
{
uint64_t v_x_boxed_20_; uint64_t v_res_21_; lean_object* v_r_22_; 
v_x_boxed_20_ = lean_unbox_uint64(v_x_19_);
lean_dec_ref(v_x_19_);
v_res_21_ = l_add3(v_x_boxed_20_);
v_r_22_ = lean_box_uint64(v_res_21_);
return v_r_22_;
}
}
LEAN_EXPORT lean_object* l_doubleNat(lean_object* v_n_23_){
_start:
{
lean_object* v___x_24_; 
v___x_24_ = lean_nat_add(v_n_23_, v_n_23_);
return v___x_24_;
}
}
LEAN_EXPORT lean_object* l_doubleNat___boxed(lean_object* v_n_25_){
_start:
{
lean_object* v_res_26_; 
v_res_26_ = l_doubleNat(v_n_25_);
lean_dec(v_n_25_);
return v_res_26_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
void lean_initialize_runtime_module();
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lib(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
lean_initialize_runtime_module();
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
