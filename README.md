# Dynamic ROC Curve Plotter

## Description
The Dynamic ROC Curve Plotter is a Shiny web application designed to allow users to upload their own datasets and dynamically generate ROC (Receiver Operating Characteristic) curves for different predictors. This application provides a user-friendly interface for generating and comparing multiple ROC curves, making it an ideal tool for researchers and analysts who need to evaluate the performance of binary classifiers.

## Features
- Data Upload: Users can upload Excel files (.xlsx) containing their data.
- Dynamic Column Selection: Select the group (binary outcome) column and up to five predictor columns from the uploaded data.
- ROC Curve Generation: Generate and visualize ROC curves for selected predictors.
- Combined ROC Curve: Create a combined ROC curve using multiple predictors.
- Plot Customization: Adjust the width and height of the generated plots.
- Download Options: Download the ROC plots in PNG or PDF format.

## Dependencies/packages
- shiny
- pROC
- readxl
- dplyr
- glmnet
- ggplot2
