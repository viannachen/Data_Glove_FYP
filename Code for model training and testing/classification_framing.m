%%
close all;
clear;

% Import data
F = readtable('trainingdata.xlsx');
xTrain = F{:,1:end-2};

X = readtable('outputdata.xlsx');
xTest = X{:,1:end-2};

% Slicing

frame_size = 10; 
for i = 1:fix(size(xTrain,1)/frame_size)
%     frameF(:,:,i) = xTrain(((i-1)*frame_size + 1):i*frame_size,:);
    frameF(i,:) = reshape(xTrain(((i-1)*frame_size + 1):i*frame_size,:), 1,[]);
    yTrain(i) = F{(i-1)*frame_size + 1, end};
end

for j = 1:fix(size(xTest,1)/frame_size)
%     frameX(:,:,j) = xTest(((j-1)*frame_size + 1):j*frame_size,:);
    frameX(j,:) = reshape(xTest(((j-1)*frame_size + 1):j*frame_size,:), 1,[]);

    yTest(j) = X{(j-1)*frame_size + 1, end};
end

yTrain = char(yTrain');
yTest =char(yTest');

%%
% Algorithm selection
t = templateSVM('KernelFunction','linear','Solver','ISDA','Standardize',true)
% t = templateTree('Surrogate','on','MaxNumSplits',1)
% t = templateKNN('NumNeighbors',10,'Standardize',1)

SVMModel = fitcecoc(frameF,categorical(cellstr(yTrain)),'Learners', t,...
    'ClassNames',{'A','B','C','D','E','F','G','H','I'});

%%
%Training data accuracy
[label,score] = predict(SVMModel,frameF);

correct=0;
for j = 1:size(label,1)
    if(yTrain(j) == label{j})
        correct = correct + 1;
    end
end
Trainingaccuracy = correct/(size(yTrain,1))

%%
%Testing data accuracy
[label,score] = predict(SVMModel,frameX);

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
cm.Title = 'SVM on windowing';
cm.XLabel = 'Predicted Class'
cm.YLabel = 'Actual Class'