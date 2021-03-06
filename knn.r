setwd(".")
options(stringsAsFactors = FALSE)
library("clusterSim")
library("PRROC")
library("e1071")

# Matthews correlation coefficient
mcc <- function (actual, predicted)
{
  # Compute the Matthews correlation coefficient (MCC) score
  # Jeff Hebert 9/1/2016
  # Geoffrey Anderson 10/14/2016 
  # Added zero denominator handling.
  # Avoided overflow error on large-ish products in denominator.
  #
  # actual = vector of true outcomes, 1 = Positive, 0 = Negative
  # predicted = vector of predicted outcomes, 1 = Positive, 0 = Negative
  # function returns MCC
  
  TP <- sum(actual == 1 & predicted == 1)
  TN <- sum(actual == 0 & predicted == 0)
  FP <- sum(actual == 0 & predicted == 1)
  FN <- sum(actual == 1 & predicted == 0)
  #TP;TN;FP;FN # for debugging
  sum1 <- TP+FP; sum2 <-TP+FN ; sum3 <-TN+FP ; sum4 <- TN+FN;
  denom <- as.double(sum1)*sum2*sum3*sum4 # as.double to avoid overflow error on large products
  if (any(sum1==0, sum2==0, sum3==0, sum4==0)) {
    denom <- 1
  }
  mcc <- ((TP*TN)-(FP*FN)) / sqrt(denom)
  return(mcc)
}

prc_data_norm <- read.csv(file="cervical_arranged_NORM.csv",head=TRUE,sep=",",stringsAsFactors=FALSE)

prc_data_norm <- prc_data_norm[sample(nrow(prc_data_norm)),] # shuffle the rows

target_index <- dim(prc_data_norm)[2]

# the training set is the first 60% of the whole dataset
training_set_first_index <- 1 # NEW
training_set_last_index <- round(dim(prc_data_norm)[1]*60/100) # NEW

# the validation set is the following 20% of the whole dataset
validation_set_first_index <- round(dim(prc_data_norm)[1]*60/100)+1 # NEW
validation_set_last_index <- round(dim(prc_data_norm)[1]*80/100) # NEW

# the test set is the last 20% of the whole dataset
test_set_first_index <- round(dim(prc_data_norm)[1]*80/100)+1 # NEW
test_set_last_index <- dim(prc_data_norm)[1] # NEW

cat("[Creating the subsets for the values]\n")
prc_data_train <- prc_data_norm[training_set_first_index:training_set_last_index, 1:(target_index-1)] # NEW
prc_data_validation <- prc_data_norm[validation_set_first_index:validation_set_last_index, 1:(target_index-1)] # NEW
prc_data_test <- prc_data_norm[test_set_first_index:test_set_last_index, 1:(target_index-1)] # NEW

cat("[Creating the subsets for the labels \"1\"-\"0\"]\n")
prc_data_train_labels <- prc_data_norm[training_set_first_index:training_set_last_index, target_index] # NEW
prc_data_validation_labels <- prc_data_norm[validation_set_first_index:validation_set_last_index, target_index] # NEW
prc_data_test_labels <- prc_data_norm[test_set_first_index:test_set_last_index, target_index]   # NEW

library(class)
library(gmodels)

# # The k value must be lower than the size of the trainingset
maxK <- 30 #NEW

mcc_array <- character(length(maxK))

# NEW PART:

cat("\n[Optimization of the hyper-parameter k start]\n")
# optimizaion loop
for(thisK in 1:maxK)
{
  # apply k-NN with the current K value
  # train on the training set, evaluate in the validation set by computing the MCC
  # save the MCC corresponding to the current K value
  
  cat("[Training the kNN model (with k=",thisK,") on training set & applying the kNN model to validation set]\n", sep="")
  
  prc_data_validation_pred <- knn(train = prc_data_train, test = prc_data_validation, cl = prc_data_train_labels, k=thisK)
  
  # CrossTable(x=prc_data_validation_labels, y=prc_data_validation_pred, prop.chisq=FALSE)
  
  prc_data_validation_labels_binary_TEMP <- replace(prc_data_validation_labels, prc_data_validation_labels=="M", 1)
  prc_data_validation_labels_binary <- replace(prc_data_validation_labels_binary_TEMP, prc_data_validation_labels=="B", 0)
  prc_data_validation_labels_binary <- as.numeric (prc_data_validation_labels_binary)
  # prc_data_validation_labels_binary
  
  prc_data_validation_pred_AS_CHAR <- as.character(prc_data_validation_pred)
  prc_data_validation_pred_binary_TEMP <- replace(prc_data_validation_pred_AS_CHAR, prc_data_validation_pred_AS_CHAR=="M", 1)
  prc_data_validation_pred_binary <- replace(prc_data_validation_pred_binary_TEMP, prc_data_validation_pred_AS_CHAR=="B", 0)
  prc_data_validation_pred_binary <- as.numeric (prc_data_validation_pred_binary)
  # prc_data_validation_pred_binary
  
  fg <- prc_data_validation_pred[prc_data_validation_labels==1]
  bg <- prc_data_validation_pred[prc_data_validation_labels==0]
  pr_curve <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = F)

  # plot(pr_curve)
  print(pr_curve)
  
  
  mcc_outcome <- mcc(prc_data_validation_labels_binary, prc_data_validation_pred_binary)
  cat("When k=",thisK,", the MCC value is ",mcc_outcome, "\t (worst possible: -1; best possible: +1)\n", sep="")
  
  mcc_array[thisK] <- mcc_outcome
  
}

# select the k corresponding to the highest MCC and call it k_best
bestMCC <- max(mcc_array)
bestK <- match(bestMCC, mcc_array)
cat("\nThe best k value is ", bestK,", corresponding to MCC=", mcc_array[bestK],"\n", sep="")

cat("[Optimization end]\n\n")


# apply k-NN with k_best to the test set

cat("[Training the kNN model (with the OPTIMIZED hyper-parameter k=",bestK,") on training set & applying the kNN to the test set]\n", sep="")
prc_data_test_pred <- knn(train = prc_data_train, test = prc_data_test, cl = prc_data_train_labels, k=bestK)

prc_data_test_labels_binary_TEMP <- replace(prc_data_test_labels, prc_data_test_labels=="M", 1)
prc_data_test_labels_binary <- replace(prc_data_test_labels_binary_TEMP, prc_data_test_labels=="B", 0)
prc_data_test_labels_binary <- as.numeric (prc_data_test_labels_binary)
# prc_data_test_labels_binary

prc_data_test_pred_AS_CHAR <- as.character(prc_data_test_pred)
prc_data_test_pred_binary_TEMP <- replace(prc_data_test_pred_AS_CHAR, prc_data_test_pred_AS_CHAR=="M", 1)
prc_data_test_pred_binary <- replace(prc_data_test_pred_binary_TEMP, prc_data_test_pred_AS_CHAR=="B", 0)
prc_data_test_pred_binary <- as.numeric (prc_data_test_pred_binary)
# prc_data_test_pred_binary

fg_test <- prc_data_test_pred[prc_data_test_labels==1]
bg_test <- prc_data_test_pred[prc_data_test_labels==0]
pr_curve_test <- pr.curve(scores.class0 = fg_test, scores.class1 = bg_test, curve = F)
#plot(pr_curve_test)
print(pr_curve_test)

mcc_outcome <- mcc(prc_data_test_labels_binary, prc_data_test_pred_binary)
cat("\nThe MCC value is ",mcc_outcome, " (worst possible: -1; best possible: +1)\n\n\n", sep="")




