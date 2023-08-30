// Run optimize-batch-matmul pass only and check the results.
// RUN: tf-opt %s -tfl-optimize-batch-matmul | FileCheck %s

// CHECK-LABEL: FuseTransposeFCRhsToBatchMatmul
func.func @FuseTransposeFCRhsToBatchMatmul(%arg0: tensor<16x1024xf32>, %arg1: tensor<1024x128xf32>, %arg2: none) -> tensor<16x128xf32> {
  %cst = arith.constant dense<[1, 0]> : tensor<2xi32>
  %0 = "tfl.transpose"(%arg1, %cst) : (tensor<1024x128xf32>, tensor<2xi32>) -> tensor<128x1024xf32>
  // CHECK: "tfl.batch_matmul"(%arg0, %arg1)
  %1 = "tfl.fully_connected"(%arg0, %0, %arg2) {asymmetric_quantize_inputs = false, fused_activation_function = "NONE", keep_num_dims = false, weights_format = "DEFAULT"} : (tensor<16x1024xf32>, tensor<128x1024xf32>, none) -> tensor<16x128xf32>
  func.return %1 : tensor<16x128xf32>
  // CHECK: return %0 : tensor<16x128xf32>
}

// CHECK-LABEL: FuseTransposeFCLhsToBatchMatmul
func.func @FuseTransposeFCLhsToBatchMatmul(%arg0: tensor<1024x4xf32>, %arg1: tensor<8x1024xf32>, %arg2: tensor<4x256xf32>) -> tensor<8x256xf32> {
  %cst_0 = arith.constant dense<[1, 0]> : tensor<2xi32>
  %cst_1 = "tfl.no_value"() {value} : () -> none
  %0 = "tfl.transpose"(%arg0, %cst_0) : (tensor<1024x4xf32>, tensor<2xi32>) -> tensor<4x1024xf32>
  // CHECK: %[[RES0:.*]] = "tfl.batch_matmul"(%arg1, %arg0) {adj_x = false, adj_y = false, asymmetric_quantize_inputs = false} : (tensor<8x1024xf32>, tensor<1024x4xf32>) -> tensor<8x4xf32>
  %1 = "tfl.fully_connected"(%0, %arg1, %cst_1) {asymmetric_quantize_inputs = false, fused_activation_function = "NONE", keep_num_dims = false, weights_format = "DEFAULT"} : (tensor<4x1024xf32>, tensor<8x1024xf32>, none) -> tensor<4x8xf32>
  // CHECK: %[[RES1:.*]] = "tfl.batch_matmul"(%[[RES0]], %arg2) {adj_x = false, adj_y = false, asymmetric_quantize_inputs = false} : (tensor<8x4xf32>, tensor<4x256xf32>) -> tensor<8x256xf32>
  %2 = "tfl.batch_matmul"(%1, %arg2) {adj_x = true, adj_y = false, asymmetric_quantize_inputs = false} : (tensor<4x8xf32>, tensor<4x256xf32>) -> tensor<8x256xf32>
  func.return %2 : tensor<8x256xf32>
  // CHECK: return %[[RES1]] : tensor<8x256xf32>
}