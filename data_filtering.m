close all;
clear;

% Import data
T = readtable('inputdata.xlsx');
thumb = T.thumb;
index_MCP = T.index_MCP;
middle_MCP = T.middle_MCP;
index_PIP = T.index_PIP;
middle_PIP = T.middle_PIP;
label = T.label;

% Plot the original data
subplot(3, 1, 1);
plot(thumb);
hold on;
plot(index_MCP);
plot(middle_MCP);
plot(index_PIP);
plot(middle_PIP);
title('Original Data');

% Filter L selsction (mov_avg represents L)
mov_avg = 10;
data_points = size(thumb, 1);

% y1 = zeros(data_points);
% y2 = zeros(data_points);
% y3 = zeros(data_points);
% y4 = zeros(data_points);
% y5 = zeros(data_points);

% for i=mov_avg+1:data_points
%     for j = 1:mov_avg
%         y1(i-mov_avg) = y1(i-mov_avg) + thumb(i-j);
%         y2(i-mov_avg) = y2(i-mov_avg) + index_MCP(i-j);
%         y3(i-mov_avg) = y3(i-mov_avg) + middle_MCP(i-j);
%         y4(i-mov_avg) = y4(i-mov_avg) + index_PIP(i-j);
%         y5(i-mov_avg) = y5(i-mov_avg) + middle_PIP(i-j);
%     end
%     y1(i-mov_avg) = y1(i-mov_avg)/mov_avg;
%     y2(i-mov_avg) = y2(i-mov_avg)/mov_avg;
%     y3(i-mov_avg) = y3(i-mov_avg)/mov_avg;
%     y4(i-mov_avg) = y4(i-mov_avg)/mov_avg;
%     y5(i-mov_avg) = y5(i-mov_avg)/mov_avg;
% end


% Convolution
h = ones(1,mov_avg);

y1 = conv(h,thumb)./mov_avg;
y2 = conv(h,index_MCP)./mov_avg;
y3 = conv(h,middle_MCP)./mov_avg;
y4 = conv(h,index_PIP)./mov_avg;
y5 = conv(h,middle_PIP)./mov_avg;

% Plot the data after filtering
subplot(3, 1, 2);
plot(y1);
hold on;
plot(y2);
plot(y3);
plot(y4);
plot(y5);
title('Filtered Data');

% Remove the transition states
output_data_points = size(y1, 1);
j= 1;
threshold = 1; 
for i = 1:output_data_points-1
    y1_diff(i) = abs(y1(i+1)-y1(i));
    y2_diff(i) = abs(y2(i+1)-y2(i));
    y3_diff(i) = abs(y3(i+1)-y3(i));
    y4_diff(i) = abs(y4(i+1)-y4(i));
    y5_diff(i) = abs(y5(i+1)-y5(i));
    if (y1_diff(i) < threshold) && (y2_diff(i) < threshold) && ... 
            (y3_diff(i) < threshold) && (y4_diff(i) < threshold) && (y5_diff(i) < threshold)
        y1_diff(i) = y1(i+1);
        y2_diff(i) = y2(i+1);
        y3_diff(i) = y3(i+1);
        y4_diff(i) = y4(i+1);
        y5_diff(i) = y5(i+1);
        if (~(y1(i+1)==0 && y2(i+1)==0 && y3(i+1)==0 && y4(i+1)==0 && y5(i+1)==0))
            y1_out(j) = y1(i+1);
            y2_out(j) = y2(i+1);
            y3_out(j) = y3(i+1);
            y4_out(j) = y4(i+1);
            y5_out(j) = y5(i+1);
            if i+1 > size(label,1)
                label_out(j) = {'A'};
            else
                label_out(j) = label(i+1);
            end
            j= j+1; 
        end
    end    
end

% subplot(4, 1, 3);
% plot(y1_diff);
% hold on;
% plot(y2_diff);
% plot(y3_diff);
% plot(y4_diff);
% plot(y5_diff);
% title('Differentiated Data');

% Plot the output data
subplot(3, 1, 3);
plot(y1_out);
hold on;
plot(y2_out);
plot(y3_out);
plot(y4_out);
plot(y5_out);
title('Output Data');

% Generate a file containing the output data for classification
y1_out = y1_out';
y2_out = y2_out';
y3_out = y3_out';
y4_out = y4_out';
y5_out = y5_out';
label_out = label_out';

output_dataset = dataset(y1_out,y2_out,y3_out,y4_out,y5_out,label_out);
output_table = dataset2table(output_dataset);
writetable(output_table,'outputdata.xlsx');