# Copyright: (C) 2014 WYSIWYD Consortium
# Authors: Stéphane Lallée
# CopyPolicy: Released under the terms of the GNU GPL v2.0.
#
# cvz.thrift

/**
* cvz_IDL
*
* IDL Interface to \ref cvz services.
*/
service cvz_IDL
{
   /**
   * Start the computation of predictions trying to cope with the period.
   */
   void start();

   /**
   * Pause the computation of predictions
   */
   void pause();

   /**
   * Quit the module.
   * @return true/false on success/failure.
   */
   bool quit();  
}

/**
* cvz_mmcm_IDL
*
* IDL Interface to \ref cvz - mmcm services.
*/
service cvz_mmcm_IDL
{
   /**
   * Set the learning rate.
   */
   void setLearningRate(1:double l);
   
   /**
   * Get the current learning rate.
   */
   double getLearningRate();

   /**
   * Set the neighborhood radius (sigma).
   */
   void setSigma(1:double s);
  
   /**
   * Get the current neighborhood radius (sigma).
   */
   double getSigma();

   /**
   * Get the activity of a neuron.
   * @param x the horizontal coordinate of the neuron.
   * @param y the vertical coordinate of the neuron.
   * @param z the layer to which the neuron belongs.
   * @return Current activity of the neuron.
   */
   double getActivity(1:i32 x, 2:i32 y, 3:i32 z);
}
