//
// EmbraceModel.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
class EmbraceModelInput : MLFeatureProvider {

    /// input as 1 × 600 × 8 3-dimensional array of floats
    var input: MLMultiArray

    var featureNames: Set<String> { ["input"] }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "input" {
            return MLFeatureValue(multiArray: input)
        }
        return nil
    }

    init(input: MLMultiArray) {
        self.input = input
    }

    convenience init(input: MLShapedArray<Float>) {
        self.init(input: MLMultiArray(input))
    }

}


/// Model Prediction Output Type
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
class EmbraceModelOutput : MLFeatureProvider {

    /// Source provided by CoreML
    private let provider : MLFeatureProvider

    /// logits as 1 by 6 matrix of floats
    var logits: MLMultiArray {
        provider.featureValue(for: "logits")!.multiArrayValue!
    }

    /// logits as 1 by 6 matrix of floats
    var logitsShapedArray: MLShapedArray<Float> {
        MLShapedArray<Float>(logits)
    }

    var featureNames: Set<String> {
        provider.featureNames
    }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        provider.featureValue(for: featureName)
    }

    init(logits: MLMultiArray) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["logits" : MLFeatureValue(multiArray: logits)])
    }

    init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
class EmbraceModel {
    let model: MLModel

    /// URL of model assuming it was installed in the same bundle as this class
    class var urlOfModelInThisBundle : URL {
        let bundle = Bundle(for: self)
        return bundle.url(forResource: "EmbraceModel", withExtension:"mlmodelc")!
    }

    /**
        Construct EmbraceModel instance with an existing MLModel object.

        Usually the application does not use this initializer unless it makes a subclass of EmbraceModel.
        Such application may want to use `MLModel(contentsOfURL:configuration:)` and `EmbraceModel.urlOfModelInThisBundle` to create a MLModel object to pass-in.

        - parameters:
          - model: MLModel object
    */
    init(model: MLModel) {
        self.model = model
    }

    /**
        Construct a model with configuration

        - parameters:
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    convenience init(configuration: MLModelConfiguration = MLModelConfiguration()) throws {
        try self.init(contentsOf: type(of:self).urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct EmbraceModel instance with explicit path to mlmodelc file
        - parameters:
           - modelURL: the file url of the model

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL) throws {
        try self.init(model: MLModel(contentsOf: modelURL))
    }

    /**
        Construct a model with URL of the .mlmodelc directory and configuration

        - parameters:
           - modelURL: the file url of the model
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL, configuration: MLModelConfiguration) throws {
        try self.init(model: MLModel(contentsOf: modelURL, configuration: configuration))
    }

    /**
        Construct EmbraceModel instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    class func load(configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<EmbraceModel, Error>) -> Void) {
        load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration, completionHandler: handler)
    }

    /**
        Construct EmbraceModel instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
    */
    class func load(configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> EmbraceModel {
        try await load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct EmbraceModel instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<EmbraceModel, Error>) -> Void) {
        MLModel.load(contentsOf: modelURL, configuration: configuration) { result in
            switch result {
            case .failure(let error):
                handler(.failure(error))
            case .success(let model):
                handler(.success(EmbraceModel(model: model)))
            }
        }
    }

    /**
        Construct EmbraceModel instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
    */
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> EmbraceModel {
        let model = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
        return EmbraceModel(model: model)
    }

    /**
        Make a prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as EmbraceModelInput

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as EmbraceModelOutput
    */
    func prediction(input: EmbraceModelInput) throws -> EmbraceModelOutput {
        try prediction(input: input, options: MLPredictionOptions())
    }

    /**
        Make a prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as EmbraceModelInput
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as EmbraceModelOutput
    */
    func prediction(input: EmbraceModelInput, options: MLPredictionOptions) throws -> EmbraceModelOutput {
        let outFeatures = try model.prediction(from: input, options: options)
        return EmbraceModelOutput(features: outFeatures)
    }

    /**
        Make an asynchronous prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as EmbraceModelInput
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as EmbraceModelOutput
    */
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    func prediction(input: EmbraceModelInput, options: MLPredictionOptions = MLPredictionOptions()) async throws -> EmbraceModelOutput {
        let outFeatures = try await model.prediction(from: input, options: options)
        return EmbraceModelOutput(features: outFeatures)
    }

    /**
        Make a prediction using the convenience interface

        It uses the default function if the model has multiple functions.

        - parameters:
            - input: 1 × 600 × 8 3-dimensional array of floats

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as EmbraceModelOutput
    */
    func prediction(input: MLMultiArray) throws -> EmbraceModelOutput {
        let input_ = EmbraceModelInput(input: input)
        return try prediction(input: input_)
    }

    /**
        Make a prediction using the convenience interface

        It uses the default function if the model has multiple functions.

        - parameters:
            - input: 1 × 600 × 8 3-dimensional array of floats

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as EmbraceModelOutput
    */

    func prediction(input: MLShapedArray<Float>) throws -> EmbraceModelOutput {
        let input_ = EmbraceModelInput(input: input)
        return try prediction(input: input_)
    }

    /**
        Make a batch prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - inputs: the inputs to the prediction as [EmbraceModelInput]
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as [EmbraceModelOutput]
    */
    func predictions(inputs: [EmbraceModelInput], options: MLPredictionOptions = MLPredictionOptions()) throws -> [EmbraceModelOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results : [EmbraceModelOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result =  EmbraceModelOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}
