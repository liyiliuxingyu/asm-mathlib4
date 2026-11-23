// Lean compiler output
// Module: demo
// Imports: public import Init public meta import Init public import Init
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
uint64_t lean_uint64_mul(uint64_t, uint64_t);
uint64_t lean_uint64_add(uint64_t, uint64_t);
lean_object* lean_uint64_to_nat(uint64_t);
lean_object* l_Nat_reprFast(lean_object*);
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
lean_object* lean_nat_add(lean_object*, lean_object*);
lean_object* lean_string_append(lean_object*, lean_object*);
lean_object* lean_string_push(lean_object*, uint32_t);
lean_object* lean_get_stdout();
LEAN_EXPORT lean_object* l_fib(lean_object*);
LEAN_EXPORT lean_object* l_fib___boxed(lean_object*);
LEAN_EXPORT uint64_t l_add3(uint64_t);
LEAN_EXPORT lean_object* l_add3___boxed(lean_object*);
LEAN_EXPORT lean_object* l_doubleNat(lean_object*);
LEAN_EXPORT lean_object* l_doubleNat___boxed(lean_object*);
LEAN_EXPORT lean_object* l_IO_print___at___00IO_println___at___00main_spec__0_spec__0(lean_object*);
LEAN_EXPORT lean_object* l_IO_print___at___00IO_println___at___00main_spec__0_spec__0___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_IO_println___at___00main_spec__0(lean_object*);
LEAN_EXPORT lean_object* l_IO_println___at___00main_spec__0___boxed(lean_object*, lean_object*);
static const lean_string_object l_main___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 10, .m_capacity = 10, .m_length = 9, .m_data = "fib 20 = "};
static const lean_object* l_main___closed__0 = (const lean_object*)&l_main___closed__0_value;
static lean_once_cell_t l_main___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* l_main___closed__1;
static lean_once_cell_t l_main___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* l_main___closed__2;
static lean_once_cell_t l_main___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* l_main___closed__3;
static const lean_string_object l_main___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 12, .m_capacity = 12, .m_length = 11, .m_data = ", add3 5 = "};
static const lean_object* l_main___closed__4 = (const lean_object*)&l_main___closed__4_value;
static lean_once_cell_t l_main___closed__5_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* l_main___closed__5;
static lean_once_cell_t l_main___closed__6_once = LEAN_ONCE_CELL_INITIALIZER;
static uint64_t l_main___closed__6;
static lean_once_cell_t l_main___closed__7_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* l_main___closed__7;
static lean_once_cell_t l_main___closed__8_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* l_main___closed__8;
static lean_once_cell_t l_main___closed__9_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* l_main___closed__9;
static const lean_string_object l_main___closed__10_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 14, .m_capacity = 14, .m_length = 13, .m_data = ", double 7 = "};
static const lean_object* l_main___closed__10 = (const lean_object*)&l_main___closed__10_value;
static lean_once_cell_t l_main___closed__11_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* l_main___closed__11;
static const lean_string_object l_main___closed__12_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "14"};
static const lean_object* l_main___closed__12 = (const lean_object*)&l_main___closed__12_value;
static lean_once_cell_t l_main___closed__13_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* l_main___closed__13;
LEAN_EXPORT lean_object* _lean_main();
LEAN_EXPORT lean_object* l_main___boxed(lean_object*);
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
LEAN_EXPORT lean_object* l_IO_print___at___00IO_println___at___00main_spec__0_spec__0(lean_object* v_s_27_){
_start:
{
lean_object* v___x_29_; lean_object* v_putStr_30_; lean_object* v___x_31_; 
v___x_29_ = lean_get_stdout();
v_putStr_30_ = lean_ctor_get(v___x_29_, 4);
lean_inc_ref(v_putStr_30_);
lean_dec_ref(v___x_29_);
v___x_31_ = lean_apply_2(v_putStr_30_, v_s_27_, lean_box(0));
return v___x_31_;
}
}
LEAN_EXPORT lean_object* l_IO_print___at___00IO_println___at___00main_spec__0_spec__0___boxed(lean_object* v_s_32_, lean_object* v_a_33_){
_start:
{
lean_object* v_res_34_; 
v_res_34_ = l_IO_print___at___00IO_println___at___00main_spec__0_spec__0(v_s_32_);
return v_res_34_;
}
}
LEAN_EXPORT lean_object* l_IO_println___at___00main_spec__0(lean_object* v_s_35_){
_start:
{
uint32_t v___x_37_; lean_object* v___x_38_; lean_object* v___x_39_; 
v___x_37_ = 10;
v___x_38_ = lean_string_push(v_s_35_, v___x_37_);
v___x_39_ = l_IO_print___at___00IO_println___at___00main_spec__0_spec__0(v___x_38_);
return v___x_39_;
}
}
LEAN_EXPORT lean_object* l_IO_println___at___00main_spec__0___boxed(lean_object* v_s_40_, lean_object* v_a_41_){
_start:
{
lean_object* v_res_42_; 
v_res_42_ = l_IO_println___at___00main_spec__0(v_s_40_);
return v_res_42_;
}
}
static lean_object* _init_l_main___closed__1(void){
_start:
{
lean_object* v___x_44_; lean_object* v___x_45_; 
v___x_44_ = lean_unsigned_to_nat(20u);
v___x_45_ = l_fib(v___x_44_);
return v___x_45_;
}
}
static lean_object* _init_l_main___closed__2(void){
_start:
{
lean_object* v___x_46_; lean_object* v___x_47_; 
v___x_46_ = lean_obj_once(&l_main___closed__1, &l_main___closed__1_once, _init_l_main___closed__1);
v___x_47_ = l_Nat_reprFast(v___x_46_);
return v___x_47_;
}
}
static lean_object* _init_l_main___closed__3(void){
_start:
{
lean_object* v___x_48_; lean_object* v___x_49_; lean_object* v___x_50_; 
v___x_48_ = lean_obj_once(&l_main___closed__2, &l_main___closed__2_once, _init_l_main___closed__2);
v___x_49_ = ((lean_object*)(l_main___closed__0));
v___x_50_ = lean_string_append(v___x_49_, v___x_48_);
return v___x_50_;
}
}
static lean_object* _init_l_main___closed__5(void){
_start:
{
lean_object* v___x_52_; lean_object* v___x_53_; lean_object* v___x_54_; 
v___x_52_ = ((lean_object*)(l_main___closed__4));
v___x_53_ = lean_obj_once(&l_main___closed__3, &l_main___closed__3_once, _init_l_main___closed__3);
v___x_54_ = lean_string_append(v___x_53_, v___x_52_);
return v___x_54_;
}
}
static uint64_t _init_l_main___closed__6(void){
_start:
{
uint64_t v___x_55_; uint64_t v___x_56_; 
v___x_55_ = 5ULL;
v___x_56_ = l_add3(v___x_55_);
return v___x_56_;
}
}
static lean_object* _init_l_main___closed__7(void){
_start:
{
uint64_t v___x_57_; lean_object* v___x_58_; 
v___x_57_ = lean_uint64_once(&l_main___closed__6, &l_main___closed__6_once, _init_l_main___closed__6);
v___x_58_ = lean_uint64_to_nat(v___x_57_);
return v___x_58_;
}
}
static lean_object* _init_l_main___closed__8(void){
_start:
{
lean_object* v___x_59_; lean_object* v___x_60_; 
v___x_59_ = lean_obj_once(&l_main___closed__7, &l_main___closed__7_once, _init_l_main___closed__7);
v___x_60_ = l_Nat_reprFast(v___x_59_);
return v___x_60_;
}
}
static lean_object* _init_l_main___closed__9(void){
_start:
{
lean_object* v___x_61_; lean_object* v___x_62_; lean_object* v___x_63_; 
v___x_61_ = lean_obj_once(&l_main___closed__8, &l_main___closed__8_once, _init_l_main___closed__8);
v___x_62_ = lean_obj_once(&l_main___closed__5, &l_main___closed__5_once, _init_l_main___closed__5);
v___x_63_ = lean_string_append(v___x_62_, v___x_61_);
return v___x_63_;
}
}
static lean_object* _init_l_main___closed__11(void){
_start:
{
lean_object* v___x_65_; lean_object* v___x_66_; lean_object* v___x_67_; 
v___x_65_ = ((lean_object*)(l_main___closed__10));
v___x_66_ = lean_obj_once(&l_main___closed__9, &l_main___closed__9_once, _init_l_main___closed__9);
v___x_67_ = lean_string_append(v___x_66_, v___x_65_);
return v___x_67_;
}
}
static lean_object* _init_l_main___closed__13(void){
_start:
{
lean_object* v___x_69_; lean_object* v___x_70_; lean_object* v___x_71_; 
v___x_69_ = ((lean_object*)(l_main___closed__12));
v___x_70_ = lean_obj_once(&l_main___closed__11, &l_main___closed__11_once, _init_l_main___closed__11);
v___x_71_ = lean_string_append(v___x_70_, v___x_69_);
return v___x_71_;
}
}
LEAN_EXPORT lean_object* _lean_main(){
_start:
{
lean_object* v___x_73_; lean_object* v___x_74_; 
v___x_73_ = lean_obj_once(&l_main___closed__13, &l_main___closed__13_once, _init_l_main___closed__13);
v___x_74_ = l_IO_println___at___00main_spec__0(v___x_73_);
return v___x_74_;
}
}
LEAN_EXPORT lean_object* l_main___boxed(lean_object* v_a_75_){
_start:
{
lean_object* v_res_76_; 
v_res_76_ = _lean_main();
return v_res_76_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
void lean_initialize_runtime_module();
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_demo(uint8_t builtin) {
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
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
return lean_io_result_mk_ok(lean_box(0));
}
char ** lean_setup_args(int argc, char ** argv);
#if defined(WIN32) || defined(_WIN32)
#include <windows.h>
#endif
lean_object* run_main(int argc, char ** argv) {
    return _lean_main();
}
int main(int argc, char ** argv) {
#if defined(WIN32) || defined(_WIN32)
  SetErrorMode(SEM_FAILCRITICALERRORS);
  SetConsoleOutputCP(CP_UTF8);
#endif
  lean_object* res;
  argv = lean_setup_args(argc, argv);
  res = initialize_demo(1 /* builtin */);
  lean_io_mark_end_initialization();
  if (lean_io_result_is_ok(res)) {
    lean_dec_ref(res);
    lean_init_task_manager();
    res = lean_run_main(&run_main, argc, argv);
  }
  lean_finalize_task_manager();
  if (lean_io_result_is_ok(res)) {
    int ret = 0;
    lean_dec_ref(res);
    return ret;
  } else {
    lean_io_result_show_error(res);
    lean_dec_ref(res);
    return 1;
  }
}
#ifdef __cplusplus
}
#endif
