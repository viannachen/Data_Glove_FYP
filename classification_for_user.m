%%
close all;
clear;

% Import data
F = readtable('trainingdata.xlsx');
xTrain = F{:,1:end-1};
xTrain = xTrain';
yTrain = F{:,end};
yTrain = char(yTrain);

X = readtable('outputdata.xlsx');
xTest = X{:,1:end};
xTest = xTest';

%%
% Algorithm selection
t = templateSVM('KernelFunction','linear','Solver','ISDA','Standardize',true)

SVMModel = fitcecoc(xTrain',categorical(cellstr(yTrain)),'Learners', t,...
    'ClassNames',{'A','B','C','D','E','F','G','H','I','U'});

%%
%Prediction
[label,score] = predict(SVMModel,xTest');

%%
% Report generation
output_dataset = dataset(label);
output_table = dataset2table(output_dataset);
writetable(output_table,'motions_classification.xlsx');

