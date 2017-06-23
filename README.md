# Cervical cancer predictions
A deep learning method for prediction of cervical cancer diagnoses from risk factors

This code implements a deep artificial neural network which uses a rectifier linear unit (ReLU) as activaction function, optimizes the hyper-parameters of hidden units and hidden layers, has learning rate = 0.01, iterations = 200 (this values are not final: you're welcome to test alternative ones). Dropout, Xavier initialization, and momentum can be turned on.

The program reads a dataset of profiles of cervical cancer patients (858 patients-rows * 33 features-columns), downloaded from the [University of California Irvine Machine Learning Repository](http://archive.ics.uci.edu/ml/datasets/Cervical+cancer+%28Risk+Factors%29). The binary target to predict is the last column on the right ("Biopsy").

The program splits the input dataset into three subsets: training set 60%, validation set 20%, test set 20%. The data instances for each subset are chosen randomly by the program. The program then starts a loop for the optimization of the hyper-parameters: for each hyper-parameter value, it trains the neural network model on the training set, appies the trained model to the validation set, and saves its result (measured with the Matthews correlation coefficient (MCC)). At the end of the loop, the program selects the model who obtained the best MCC, and applies it to the held-out test test. That is the last test.

To run the program on your Linux machine, install Torch and then type:

`th cervical_ann_script_val.lua cervical_arranged_NORM.csv`

A new version with 10-fold cross validation is available. The k-fold cross validation is applied to 80% of the dataset, which is split to training set and validation set at each iteration. Finally, the best trained model is applied to the test set.
To run the script with the k-fold cross validation, type:

`th cervical_ann_script_val_kfold.lua cervical_arranged_NORM.csv`

For any question: davide.chicco(AT)gmail.com
