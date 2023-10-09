// swift-tools-version:5.6
//
//  Package.swift
//  PotentCodables
//
//  Copyright © 2019 Outfox, inc.
//
//
//  Distributed under the MIT License, See LICENSE for details.
//

import PackageDescription

let package = Package(
  name: "PotentCodables",
  platforms: [
    .iOS(.v10),
    .macOS(.v10_12),
    .watchOS(.v3),
    .tvOS(.v10),
  ],
  products: [
    .library(
      name: "PotentCodables",              
      targets: ["PotentCodables", "PotentJSON", "PotentCBOR", "PotentASN1", "Cfyaml"]
      // targets: ["PotentCodables", "PotentJSON", "PotentCBOR", "PotentASN1", "PotentYAML", "Cfyaml"]
    )
  ],
   dependencies: [
    .package(url: "https://github.com/vinidiktov/BigIntKit.git", revision: "46ea3d4be50b198468f14f899753e58d85be7499"),
    .package(url: "https://github.com/vinidiktov/OrderedDictionaryKit.git", revision: "e80bab83da7ac298c848bbec657c576a7260d8c0"),  
   ],
  targets: [
    .target(
      name: "PotentCodables"
    ),
    .target(
      name: "PotentJSON",
      dependencies: ["PotentCodables"]
    ),
    .target(
      name: "PotentCBOR",
      dependencies: ["PotentCodables"]
    ),
    .target(
      name: "PotentASN1",
      dependencies: ["PotentCodables", "BigIntKit", "OrderedDictionaryKit"]
    ),
    .target(    
      name: "Cfyaml",
      cSettings: [
        .headerSearchPath("config"),
        .headerSearchPath("lib"),
        .headerSearchPath("valgrind"),
        .define("HAVE_CONFIG_H")
      ]
    ),
    .target(
      name: "PotentYAMLKit",
      dependencies: ["Cfyaml", "PotentCodables"],
      path: "Sources/PotentYAML"
    ),
    .testTarget(
      name: "PotentCodablesTests",
      dependencies: ["PotentCodables", "PotentJSON", "PotentCBOR", "PotentASN1"],
      // dependencies: ["PotentCodables", "PotentJSON", "PotentCBOR", "PotentASN1", "PotentYAML"],
      path: "./Tests"
    ),
  ]
)
