%%
close all;
clear;

% Import data
F = readtable('outputdataX.xlsx');
xTrain = F{:,1:end-1};
xTrain = xTrain';
yTrain = F{:,end};
yTrain = char(yTrain);

X = readtable('outputdataY.xlsx');
xTest = X{:,1:end-1};
xTest = xTest';
yTest = X{:,end};
yTest = char(yTest);

%%
% Algorithm selection
t = templateSVM('KernelFunction','linear','Solver','ISDA','Standardize',true)
% t = templateTree('Surrogate','on','MaxNumSplits',1)
% t = templateKNN('NumNeighbors',8,'Standardize',1)

SVMModel = fitcecoc(xTrain',categorical(cellstr(yTrain)),'Learners', t,...
    'ClassNames',{'A','B','C','D','E','F','G','H','I','U'});

%%
% Training data accuracy
[label,score] = predict(SVMModel,xTrain');

correct=0;
for j = 1:size(label,1)
    if(yTrain(j) == label{j})
        correct = correct + 1;
    end
end
Trainingaccuracy = correct/(size(yTrain,1))

%%
%Testing data accuracy
[label,score] = predict(SVMModel,xTest');

correct=0;
for j = 1:size(label,1)
    if(yTest(j) == label{j})
        correct = correct + 1;
    end
end
Testingaccuracy = correct/(size(yTest,1))

%%
% Plot the comfusion matrix
cm= confusionchart(cellstr(yTest), label);
cm.Title = 'Testing data accuracy for All Users';
cm.XLabel = 'Predicted Class'
cm.YLabel = 'Actual Class'

%%
% Report generation
output_dataset = dataset(label);
output_table = dataset2table(output_dataset);
writetable(output_table,'motions_classification.xlsx');

