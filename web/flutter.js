// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/**
 * This script is used to load the Flutter web app.
 */

'use strict';

/**
 * Handles the initial loading of the Flutter app.
 */
class FlutterLoader {
  /**
   * Creates a FlutterLoader.
   */
  constructor() {
    this._didInitialize = false;
    this._didCreateEngine = false;
  }

  /**
   * Initializes the Flutter engine.
   * @returns {Promise<void>} A promise that resolves when the engine is initialized.
   */
  async initializeEngine() {
    if (this._didInitialize) {
      return;
    }
    this._didInitialize = true;
    
    // This is a placeholder for the actual Flutter engine initialization.
    // In a real implementation, this would load the Flutter engine.
    console.log('Flutter engine initialized');
    
    return Promise.resolve();
  }

  /**
   * Loads the entrypoint for the Flutter app.
   * @param {Object} options Options for loading the entrypoint.
   * @returns {Promise<Object>} A promise that resolves with the app runner.
   */
  async loadEntrypoint(options) {
    await this.initializeEngine();
    
    if (!this._didCreateEngine) {
      this._didCreateEngine = true;
      
      // This is a placeholder for the actual Flutter app loading.
      // In a real implementation, this would load the Flutter app.
      console.log('Flutter app loaded');
      
      const engineInitializer = {
        initializeEngine: () => {
          return Promise.resolve({
            runApp: () => {
              console.log('Flutter app running');
            }
          });
        }
      };
      
      if (options.onEntrypointLoaded) {
        options.onEntrypointLoaded(engineInitializer);
      }
    }
    
    return Promise.resolve();
  }
}

// Create a global _flutter object with a loader property.
window._flutter = {
  loader: new FlutterLoader()
};