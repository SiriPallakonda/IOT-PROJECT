%% PRIVACY PRESERVING EDGE AI FOR IoT SURVEILLANCE
% M.Tech CSE Project
% Complete MATLAB Prototype
% Includes simulated date/time, named camera zones, and explainable incident reasons
clear;
clc;
close all;
rng(10);
fprintf('\n============================================\n');
fprintf(' PRIVACY PRESERVING EDGE AI SURVEILLANCE\n');
fprintf('============================================\n');
%% 1. PARAMETERS
numTraining = 1000;
numTests = 1000;
%% 2. GENERATE NORMAL TRAINING DATA
walking = [ ...
 1+0.30*randn(numTraining,1), ...
 0.8+0.30*randn(numTraining,1), ...
 8+5*randn(numTraining,1), ...
 0.8+0.25*randn(numTraining,1)];
standing = [ ...
 0.1+0.08*randn(numTraining,1), ...
 0.15+0.08*randn(numTraining,1), ...
 5+4*randn(numTraining,1), ...
 0.15+0.08*randn(numTraining,1)];
running = [ ...
 2.5+0.8*randn(numTraining,1), ...
 2.5+0.9*randn(numTraining,1), ...
 20+12*randn(numTraining,1), ...
 2.2+0.8*randn(numTraining,1)];
bending = [ ...
 0.6+0.25*randn(numTraining,1), ...
 0.8+0.3*randn(numTraining,1), ...
 55+15*randn(numTraining,1), ...
 0.9+0.3*randn(numTraining,1)];
normalData = [walking; standing; running; bending];
normalData = max(normalData,0);
fprintf('\nTraining data generated.\n');
%% 3. TRAIN NORMAL BEHAVIOR MODEL
mu = mean(normalData,1);
sigma = std(normalData,0,1);
sigma(sigma<0.001)=0.001;
fprintf('Normal behavior model trained.\n');
%% EXTRA 50 SUSPICIOUS / DANGEROUS ACTIVITY LABELS
% These are annotation labels, not automatic visual recognition classes.
% Verbal abuse requires audio/transcription; silent video cannot identify speech content.
extraSuspiciousActivities = {
'Tailgating through a secured door';
'Attempting to bypass an access reader';
'Trying to enter with a stolen access card';
'Passing an object through a restricted doorway';
'Climbing onto a restricted platform';
'Entering a staff-only area without permission';
'Loitering near an emergency exit';
'Repeatedly testing a security gate';
'Interfering with a CCTV camera';
'Covering or turning away a CCTV camera';
'Attempting to disable an alarm';
'Tampering with a security panel';
'Removing a security tag';
'Breaking a door lock';
'Attempting to pick a door lock';
'Entering through an unauthorized window';
'Concealing a package in a restricted area';
'Leaving a suspicious package';
'Attempting to steal a parked vehicle';
'Attempting to access a control room'
};
extraHighRiskActivities = {
'Grabbing another person forcefully';
'Slapping another person';
'Headbutting another person';
'Kneeing another person';
'Tripping another person';
'Throwing a person to the ground';
'Dragging an unwilling person';
'Choking another person';
'Attempting to strangle another person';
'Cornering and intimidating another person';
'Threatening physical violence';
'Throwing furniture at a person';
'Throwing a heavy object at a person';
'Attacking a person with a stick';
'Attacking a person with a metal rod';
'Attempting to hit a person with a vehicle';
'Blocking a person from leaving';
'Forcibly restraining another person';
'Attempting to break into an occupied room';
'Verbal abuse or threatening language (audio-assisted)'
};
extraCriticalActivities = {
'Stabbing or attempting to stab a person';
'Attacking a person with a knife';
'Pointing a knife at another person';
'Threatening a person with a firearm';
'Brandishing a firearm';
'Firing a weapon';
'Attacking a person with a sharp object';
'Attempting to set a person or property on fire';
'Deliberate violent assault with a weapon';
'Severe physical attack on another person'
};
extraAllActivities = [extraSuspiciousActivities; extraHighRiskActivities; extraCriticalActivities];

%% 4. GENERATE VALIDATION DATA - MATCHES THE TEST EVENT GENERATOR
% The validation set uses the same 56 event types and context rules as the
% test set. It is used only to select the risk threshold.
numValidation = 2000;
validationData = zeros(numValidation,4);
validationLabel = zeros(numValidation,1);
validationLocation = cell(numValidation,1);
validationAuthorized = zeros(numValidation,1);
validationHour = zeros(numValidation,1);
validationActivity = cell(numValidation,1);

for i = 1:numValidation
    eventType = randi(56);

    switch eventType
        case 1
            validationData(i,:) = [1+0.30*randn, 0.8+0.30*randn, ...
                8+5*randn, 0.8+0.25*randn];
            validationActivity{i} = 'Walking';
            validationLocation{i} = 'Main Entrance';
            validationAuthorized(i) = 1;
            validationHour(i) = randi([8 20]);
            validationLabel(i) = 0;

        case 2
            validationData(i,:) = [0.1+0.08*randn, 0.15+0.08*randn, ...
                5+4*randn, 0.15+0.08*randn];
            validationActivity{i} = 'Standing';
            validationLocation{i} = 'Reception Area';
            validationAuthorized(i) = 1;
            validationHour(i) = randi([8 20]);
            validationLabel(i) = 0;

        case 3
            validationData(i,:) = [2.5+0.8*randn, 2.5+0.9*randn, ...
                20+12*randn, 2.2+0.8*randn];
            validationActivity{i} = 'Running';
            validationLocation{i} = 'Main Corridor';
            validationAuthorized(i) = 1;
            validationHour(i) = randi([8 20]);
            validationLabel(i) = 0;

        case 4
            validationData(i,:) = [0.6+0.25*randn, 0.8+0.3*randn, ...
                55+15*randn, 0.9+0.3*randn];
            validationActivity{i} = 'Bending';
            validationLocation{i} = 'Office Corridor';
            validationAuthorized(i) = 1;
            validationHour(i) = randi([8 20]);
            validationLabel(i) = 0;

        case 5
            validationData(i,:) = [0.5+0.45*randn, 3+1.8*randn, ...
                65+20*randn, 3+1.8*randn];
            validationActivity{i} = 'Falling';
            validationLocation{i} = 'Public Corridor';
            validationAuthorized(i) = 1;
            validationHour(i) = randi([8 20]);
            validationLabel(i) = 1;

        case 6
            validationData(i,:) = [1+0.65*randn, 1.2+0.8*randn, ...
                20+15*randn, 1.2+0.7*randn];
            validationActivity{i} = 'RestrictedEntry';
            validationLocation{i} = 'Server Room - Restricted';
            validationAuthorized(i) = 0;
            validationHour(i) = randi([0 5]);
            validationLabel(i) = 1;

        otherwise
            extraIndex = eventType - 6;
            validationActivity{i} = extraAllActivities{extraIndex};
            validationData(i,:) = [1.4+0.9*randn, 1.8+1.2*randn, ...
                35+25*randn, 1.8+1.1*randn];
            validationLabel(i) = 1;
            validationHour(i) = randi([0 23]);

            if extraIndex <= numel(extraSuspiciousActivities)
                validationLocation{i} = 'Security Perimeter Zone';
                validationAuthorized(i) = 0;
            elseif extraIndex <= numel(extraSuspiciousActivities) + ...
                    numel(extraHighRiskActivities)
                validationLocation{i} = 'Public Corridor Zone';
                validationAuthorized(i) = 1;
            else
                validationLocation{i} = 'High Security Zone';
                validationAuthorized(i) = 1;
            end
    end
end

validationData = max(validationData,0);

%% 5. VALIDATION ANOMALY SCORE
zVal = abs((validationData-repmat(mu,numValidation,1)) ...
    ./repmat(sigma,numValidation,1));
anomalyVal = mean(zVal,2);
anomalyVal = anomalyVal./(1+anomalyVal);

%% 6. VALIDATION CONTEXT SCORE
% These rules deliberately match Section 10 (test context analysis).
contextVal = zeros(numValidation,1);
for i = 1:numValidation
    score = 0;
    if contains(validationLocation{i},'Restricted')
        score = score + 0.20;
    end
    if validationAuthorized(i) == 0
        score = score + 0.25;
    end
    if validationHour(i) < 6 || validationHour(i) > 22
        score = score + 0.10;
    end
    if strcmp(validationActivity{i},'Falling')
        score = score + 0.15;
    end
    contextVal(i) = min(score,1);
end

%% 7. SELECT THRESHOLD USING BALANCED ACCURACY
riskVal = 0.50*anomalyVal + 0.50*contextVal;
thresholds = 0.05:0.01:0.95;
bestThreshold = 0.30;
bestBalancedAccuracy = -1;
bestValidationF1 = 0;

for t = thresholds
    predictionVal = double(riskVal >= t);
    TPv = sum(validationLabel==1 & predictionVal==1);
    TNv = sum(validationLabel==0 & predictionVal==0);
    FPv = sum(validationLabel==0 & predictionVal==1);
    FNv = sum(validationLabel==1 & predictionVal==0);

    sensitivityVal = TPv/(TPv+FNv+eps);
    specificityVal = TNv/(TNv+FPv+eps);
    balancedAccuracyVal = (sensitivityVal+specificityVal)/2;

    precisionVal = TPv/(TPv+FPv+eps);
    f1Val = 2*precisionVal*sensitivityVal / ...
        (precisionVal+sensitivityVal+eps);

    if balancedAccuracyVal > bestBalancedAccuracy
        bestBalancedAccuracy = balancedAccuracyVal;
        bestValidationF1 = f1Val;
        bestThreshold = t;
    end
end

fprintf('\n========== VALIDATION RESULTS ==========\n');
fprintf('Selected threshold       : %.2f\n',bestThreshold);
fprintf('Validation balanced acc. : %.2f %%\n', ...
    bestBalancedAccuracy*100);
fprintf('Validation F1 score      : %.2f %%\n', ...
    bestValidationF1*100);



%% 8. GENERATE TEST EVENTS
testData=zeros(numTests,4);
groundTruth=zeros(numTests,1);
activity=cell(numTests,1);
location=cell(numTests,1);
authorized=zeros(numTests,1);
hour=zeros(numTests,1);
eventDateTime=NaT(numTests,1); % Simulated event timestamp
for i=1:numTests
 eventType=randi(56);
 if eventType > 6
     extraIndex = eventType - 6;
     activity{i} = extraAllActivities{extraIndex};
     testData(i,:) = [1.4+0.9*randn, 1.8+1.2*randn, ...
                      35+25*randn, 1.8+1.1*randn];
     groundTruth(i) = 1;
     if extraIndex <= numel(extraSuspiciousActivities)
         location{i} = 'Security Perimeter Zone';
         authorized(i) = 0;
     elseif extraIndex <= numel(extraSuspiciousActivities)+numel(extraHighRiskActivities)
         location{i} = 'Public Corridor Zone';
         authorized(i) = 1;
     else
         location{i} = 'High Security Zone';
         authorized(i) = 1;
     end
     hour(i) = randi([0 23]);
     simulatedDate = datetime(2025,11,18) + days(randi([0 6]));
     eventDateTime(i) = simulatedDate + hours(hour(i)) + minutes(randi([0 59]));
     continue;
 end
 switch eventType
 case 1
 testData(i,:)=[ ...
 1+0.30*randn, 0.8+0.30*randn,...
 8+5*randn, 0.8+0.25*randn];
 activity{i}='Walking';
 location{i}='Main Entrance';
 authorized(i)=1;
 hour(i)=randi([8 20]);
 groundTruth(i)=0;
 case 2
 testData(i,:)=[ ...
 0.1+0.08*randn, 0.15+0.08*randn,...
 5+4*randn, 0.15+0.08*randn];
 activity{i}='Standing';
 location{i}='Reception Area';
 authorized(i)=1;
 hour(i)=randi([8 20]);
 groundTruth(i)=0;
 case 3
 testData(i,:)=[ ...
 2.5+0.8*randn, 2.5+0.9*randn,...
 20+12*randn, 2.2+0.8*randn];
 activity{i}='Running';
 location{i}='Main Corridor';
 authorized(i)=1;
 hour(i)=randi([8 20]);
 groundTruth(i)=0;
 case 4
 testData(i,:)=[ ...
 0.6+0.25*randn, 0.8+0.3*randn,...
 55+15*randn, 0.9+0.3*randn];
 activity{i}='Bending';
 location{i}='Office Corridor';
 authorized(i)=1;
 hour(i)=randi([8 20]);
 groundTruth(i)=0;
 case 5
 testData(i,:)=[ ...
 0.5+0.45*randn, 3+1.8*randn,...
 65+20*randn, 3+1.8*randn];
 activity{i}='Falling';
 location{i}='Public Corridor';
 authorized(i)=1;
 hour(i)=randi([8 20]);
 groundTruth(i)=1;
 case 6
 testData(i,:)=[ ...
 1+0.65*randn, 1.2+0.8*randn,...
 20+15*randn, 1.2+0.7*randn];
 activity{i}='RestrictedEntry';
 location{i}='Server Room - Restricted';
 authorized(i)=0;
 hour(i)=randi([0 5]);
 groundTruth(i)=1;
 end
 % Create a reproducible-style simulated date and time for this event.
 % Replace this timestamp with the camera/video timestamp in a real deployment.
 simulatedDate = datetime(2025,11,18) + days(randi([0 6]));
 eventDateTime(i) = simulatedDate + hours(hour(i)) + minutes(randi([0 59]));
end
testData=max(testData,0);
fprintf('Test data generated.\n');
%% 9. ANOMALY DETECTION
z=abs((testData-repmat(mu,numTests,1))...
 ./repmat(sigma,numTests,1));
anomalyScore=mean(z,2);
anomalyScore=anomalyScore./(1+anomalyScore);
%% 10. CONTEXT ANALYSIS
contextScore=zeros(numTests,1);
for i=1:numTests
 score=0;
 if contains(location{i},'Restricted')
 score=score+0.20;
 end
 if authorized(i)==0
 score=score+0.25;
 end
 if hour(i)<6 || hour(i)>22
 score=score+0.10;
 end
 if strcmp(activity{i},'Falling')
 score=score+0.15;
 end
 contextScore(i)=min(score,1);
end
%% 11. RISK SCORE
riskScore=0.50*anomalyScore+0.50*contextScore;
%% 12. ACTIVITY AND RISK CLASSIFICATION
% Do not classify every unusual movement as suspicious.
% First identify the activity group, then apply context-based risk rules.
severity = cell(numTests,1);
activityCategory = cell(numTests,1);
normalLabels = {'Walking','Standing','Sitting','Running','Jogging','Talking', ...
 'Looking around','Using mobile phone','Reading','Writing','Drinking water', ...
 'Eating','Opening a door','Closing a door','Entering a room','Exiting a room', ...
 'Climbing stairs','Descending stairs','Carrying a bag','Carrying a box', ...
 'Picking up an object','Placing an object','Waving hand','Greeting someone', ...
 'Shaking hands','Bending'};
workLabels = {'Working on computer','Typing','Using a printer','Cleaning', ...
 'Sweeping','Mopping','Arranging objects','Moving furniture','Waiting', ...
 'Standing in a queue','Discussing with another person','Teaching', ...
 'Writing on a board','Operating equipment','Inspecting equipment', ...
 'Repairing equipment','Delivering a package','Receiving a package', ...
 'Loading objects','Unloading objects'};
suspiciousLabels = {'Repeatedly looking around','Loitering', ...
 'Repeatedly walking past an entrance','Attempting to open a locked door', ...
 'Entering a restricted area','Remaining in a restricted area', ...
 'Climbing over a fence','Hiding behind an object', ...
 'Crouching near a secured entrance','Tampering with equipment', ...
 'Removing an unattended object','Leaving an unattended bag', ...
 'Following another person','Entering after closing hours', ...
 'Repeatedly checking a window','Trying multiple door handles', ...
 'Unauthorized access attempt','Moving around a secured perimeter', ...
 'Concealing an object','Forcing open a door', extraSuspiciousActivities{:}};
emergencyLabels = {'Falling','Slipping','Fainting','Lying motionless','Fighting', ...
 'Punching','Kicking','Pushing another person','Chasing another person', ...
 'Aggressive physical interaction','Throwing an object','Breaking an object', ...
 'Breaking a window','Physical assault','Person collapsing', ...
 'Sudden crowd movement','Panic movement','Fire evacuation', ...
 'Smoke-related emergency','Person trapped', ...
 extraHighRiskActivities{:}, extraCriticalActivities{:}};
criticalLabels = {'Fighting','Punching','Kicking','Aggressive physical interaction', ...
 'Physical assault','Threatening with a knife','Brandishing a knife', ...
 'Forcing open a door', extraCriticalActivities{:}};
objectLabels = {'Holding a knife','Carrying a knife','Placing a knife on a table', ...
 'Using a knife for cooking','Threatening with a knife','Brandishing a knife', ...
 'Holding a mobile phone','Carrying a backpack','Carrying a suitcase', ...
 'Holding a bottle','Holding a stick','Carrying a metal rod', ...
 'Holding scissors','Carrying a tool','Dropping an object'};
for i = 1:numTests
 a = activity{i};
 % Step 1: activity category (what the person is doing)
 if any(strcmpi(a,normalLabels))
 activityCategory{i} = 'NORMAL ACTIVITY';
 severity{i} = 'NORMAL';
 elseif any(strcmpi(a,workLabels))
 activityCategory{i} = 'WORKPLACE ACTIVITY';
 severity{i} = 'NORMAL';
 elseif any(strcmpi(a,suspiciousLabels)) || strcmpi(a,'RestrictedEntry')
 activityCategory{i} = 'SUSPICIOUS BEHAVIOUR';
 severity{i} = 'SUSPICIOUS';
 elseif any(strcmpi(a,emergencyLabels))
 activityCategory{i} = 'EMERGENCY / SAFETY EVENT';
 severity{i} = 'HIGH RISK';
 elseif any(strcmpi(a,objectLabels))
 activityCategory{i} = 'OBJECT-RELATED ACTIVITY';
 severity{i} = 'NORMAL'; % object presence alone is not a threat
 else
 activityCategory{i} = 'UNCLASSIFIED / REVIEW';
 severity{i} = 'NORMAL'; % unknown must not automatically mean suspicious
 end
 % Step 2: context-based overrides
 % A normal action such as running remains normal unless context supports risk.
 if strcmpi(a,'RestrictedEntry') || ...
 contains(lower(a),'restricted area') || ...
 contains(lower(a),'unauthorized access') || ...
 contains(lower(a),'forcing open')
 if authorized(i)==0
 if hour(i)<6 || hour(i)>22
 severity{i} = 'CRITICAL';
 else
 severity{i} = 'HIGH RISK';
 end
 end
 end
 % A fall is a safety emergency, not suspicious criminal behaviour.
 if any(strcmpi(a,{'Falling','Slipping','Fainting', ...
 'Lying motionless','Person collapsing','Person trapped'}))
 severity{i} = 'HIGH RISK';
 activityCategory{i} = 'EMERGENCY / SAFETY EVENT';
 end
 % Violence or a weapon threat is critical; merely holding a knife is not.
 if any(strcmpi(a,criticalLabels))
 severity{i} = 'CRITICAL';
 if contains(lower(a),'knife') || contains(lower(a),'weapon') || ...
        contains(lower(a),'firearm') || contains(lower(a),'stabbing') || ...
        contains(lower(a),'sharp object')
     activityCategory{i} = 'WEAPON / VIOLENCE THREAT';
 else
     activityCategory{i} = 'CRITICAL VIOLENT BEHAVIOUR';
 end
 end
 if any(strcmpi(a,{'Holding a knife','Carrying a knife', ...
 'Placing a knife on a table','Using a knife for cooking'}))
 if ~any(strcmpi(a,criticalLabels))
 severity{i} = 'NORMAL';
 activityCategory{i} = 'OBJECT-RELATED ACTIVITY';
 end
 end
 % Loitering/behaviour flags need corroborating context; do not escalate
 % solely because the motion is unusual.
 if strcmpi(a,'Running') || strcmpi(a,'Jogging') || ...
 strcmpi(a,'Walking') || strcmpi(a,'Bending')
 if authorized(i)==1 && ~contains(location{i},'Restricted')
 severity{i} = 'NORMAL';
 activityCategory{i} = 'NORMAL ACTIVITY';
 end
 end
end
%% 13. NORMAL / ABNORMAL PREDICTION
% Evaluate the statistical detector independently of the descriptive
% severity rules. The threshold was selected using validation data only.
% Severity remains available for incident reporting and privacy actions.
predicted=double(riskScore>=bestThreshold);
%% 13A. EXPLAINABLE INCIDENT REASONS
reason=cell(numTests,1);
for i=1:numTests
 reasonParts={};
 if authorized(i)==0
 reasonParts{end+1}='Entry was not authorized';
 end
 if contains(location{i},'Restricted')
 reasonParts{end+1}='Activity occurred in a restricted area';
 end
 if hour(i)<6 || hour(i)>22
 reasonParts{end+1}='Activity occurred outside permitted hours';
 end
 if strcmp(activity{i},'Falling')
 reasonParts{end+1}='Possible fall detected; may require immediate assistance';
 end
 if strcmp(severity{i},'SUSPICIOUS') || strcmp(severity{i},'HIGH RISK') || ...
        strcmp(severity{i},'CRITICAL')
     reasonParts{end+1}=['Activity flagged for review: ' activity{i}];
 end
 if anomalyScore(i)>=0.50
 reasonParts{end+1}='Movement pattern differs significantly from learned normal behaviour';
 end
 if isempty(reasonParts)
 if predicted(i)==1
 reasonParts{end+1}='Combined anomaly and context risk crossed the detection threshold';
 else
 reasonParts{end+1}='No suspicious rule was triggered';
 end
 end
 reason{i}=strjoin(reasonParts,'; ');
end
%% 14. PERFORMANCE EVALUATION
TP=sum(groundTruth==1 & predicted==1);
TN=sum(groundTruth==0 & predicted==0);
FP=sum(groundTruth==0 & predicted==1);
FN=sum(groundTruth==1 & predicted==0);
accuracy=(TP+TN)/numTests*100;
precision=TP/(TP+FP+eps)*100;
recall=TP/(TP+FN+eps)*100;
specificity=TN/(TN+FP+eps)*100;
balancedAccuracy=(recall+specificity)/2;
f1Score=2*precision*recall/(precision+recall+eps);
FPR=FP/(FP+TN+eps)*100;
FNR=FN/(FN+TP+eps)*100;
fprintf('\n============================================\n');
fprintf(' MODEL PERFORMANCE RESULTS\n');
fprintf('============================================\n');
fprintf('True Positive : %d\n',TP);
fprintf('True Negative : %d\n',TN);
fprintf('False Positive : %d\n',FP);
fprintf('False Negative : %d\n',FN);
fprintf('\nAccuracy : %.2f %%\n',accuracy);
fprintf('Precision : %.2f %%\n',precision);
fprintf('Recall : %.2f %%\n',recall);
fprintf('Specificity : %.2f %%\n',specificity);
fprintf('Balanced Accuracy : %.2f %%\n',balancedAccuracy);
fprintf('F1 Score : %.2f %%\n',f1Score);
fprintf('False Positive Rate : %.2f %%\n',FPR);
fprintf('False Negative Rate : %.2f %%\n',FNR);
%% 15. CONFUSION MATRIX
CM=[TN FP; FN TP];
figure(1);
imagesc(CM);
colorbar;
axis equal;
axis tight;
set(gca,'XTick',[1 2]);
set(gca,'YTick',[1 2]);
set(gca,'XTickLabel',{'Normal','Abnormal'});
set(gca,'YTickLabel',{'Normal','Abnormal'});
xlabel('Predicted Class');
ylabel('Actual Class');
title('Confusion Matrix');
for r=1:2
 for c=1:2
 text(c,r,num2str(CM(r,c)),...
 'HorizontalAlignment','center',...
 'FontSize',14,...
 'FontWeight','bold',...
 'Color','white');
 end
end
%% 16. ROC CURVE AND AUC
positiveScores = riskScore(groundTruth==1);
negativeScores = riskScore(groundTruth==0);
% Convert both arrays into column vectors
positiveScores = positiveScores(:);
negativeScores = negativeScores(:);
% Calculate AUC using pairwise comparisons
comparisons = bsxfun(@gt, ...
 positiveScores, negativeScores') + ...
 0.5*bsxfun(@eq, ...
 positiveScores, negativeScores');
AUC = mean(comparisons(:));
% Generate ROC curve
rocThresholds = [-inf; ...
 sort(unique(riskScore),'descend'); inf];
TPR = zeros(length(rocThresholds),1);
rocFPR = zeros(length(rocThresholds),1);
for k = 1:length(rocThresholds)
 rocPrediction = riskScore >= rocThresholds(k);
 tp = sum(rocPrediction==1 & groundTruth==1);
 fp = sum(rocPrediction==1 & groundTruth==0);
 TPR(k) = tp/(TP+FN+eps);
 rocFPR(k) = fp/(FP+TN+eps);
end
figure(2);
plot(rocFPR,TPR,'b','LineWidth',2);
hold on;
plot([0 1],[0 1],'r--');
xlabel('False Positive Rate');
ylabel('True Positive Rate');
title(sprintf('ROC Curve - AUC = %.4f',AUC));
legend('Proposed Model','Random Classifier');
grid on;
fprintf('\nROC AUC: %.4f\n',AUC);
%% 17. ADAPTIVE PRIVACY ENGINE
privacyAction=cell(numTests,1);
for i=1:numTests
 switch severity{i}
 case 'NORMAL'
 privacyAction{i}='LOCAL PROCESSING ONLY';
 case 'SUSPICIOUS'
 privacyAction{i}='SEND METADATA';
 case 'HIGH RISK'
 privacyAction{i}='SEND METADATA + ANONYMIZED IMAGE';
 case 'CRITICAL'
 privacyAction{i}='SEND ALERT + ENCRYPTED EVIDENCE';
 end
end
%% 18. ALERT GENERATION AND EVENT TABLE
% Alerts are generated from the activity severity classification.
% These are MATLAB simulation alerts; no SMS, email, MQTT or push service
% is contacted by this standalone script.
AlertLevel = cell(numTests,1);
AlertMessage = cell(numTests,1);

for i = 1:numTests
    switch severity{i}
        case 'NORMAL'
            AlertLevel{i} = 'NO ALERT';
            AlertMessage{i} = 'Routine activity; no notification required';

        case 'SUSPICIOUS'
            AlertLevel{i} = 'WARNING';
            AlertMessage{i} = sprintf( ...
                'WARNING: Review %s in %s. Reason: %s', ...
                activity{i}, location{i}, reason{i});

        case 'HIGH RISK'
            AlertLevel{i} = 'URGENT';
            AlertMessage{i} = sprintf( ...
                'URGENT: Possible safety/security incident: %s in %s. Reason: %s', ...
                activity{i}, location{i}, reason{i});

        case 'CRITICAL'
            AlertLevel{i} = 'EMERGENCY';
            AlertMessage{i} = sprintf( ...
                'EMERGENCY: Critical event %s reported in %s. Immediate human verification required. Reason: %s', ...
                activity{i}, location{i}, reason{i});
    end
end

EventID=(1:numTests)';
EventDate=string(eventDateTime,'dd-MMM-yyyy');
EventTime=string(eventDateTime,'hh:mm:ss a');
TimeZone=repmat("Asia/Kolkata",numTests,1);
CameraZone=string(location);
T=table(EventID,EventDate,EventTime,TimeZone,CameraZone,activity,activityCategory,location,authorized,...
 reason,groundTruth,anomalyScore,contextScore,riskScore,...
 predicted,severity,AlertLevel,AlertMessage,privacyAction);

fprintf('\n============== ALERT SUMMARY ==============\n');
warningCount = sum(strcmp(AlertLevel,'WARNING'));
urgentCount = sum(strcmp(AlertLevel,'URGENT'));
emergencyCount = sum(strcmp(AlertLevel,'EMERGENCY'));
fprintf('Warning alerts   : %d\n',warningCount);
fprintf('Urgent alerts    : %d\n',urgentCount);
fprintf('Emergency alerts : %d\n',emergencyCount);

incidentTable=T(~strcmp(severity,'NORMAL'),:);
if isempty(incidentTable)
    fprintf('No non-normal events generated; no alerts to display.\n');
else
    fprintf('\n============== RECENT INCIDENT ALERTS ==============\n');
    alertColumns = {'EventID','EventDate','EventTime','CameraZone', ...
        'activity','severity','AlertLevel','riskScore'};
    disp(incidentTable(1:min(20,height(incidentTable)),alertColumns));
end

% Audible notification: one beep for the run if at least one critical event exists.
if emergencyCount > 0
    try
        beep;
    catch
        fprintf('Audio notification is not available on this MATLAB system.\n');
    end
end

% Visual alert dashboard: one window containing the incident list.
% Limit the initial display to 100 rows; the complete alert log is saved to CSV.
if ~isempty(incidentTable)
    try
        alertFig = uifigure('Name','IoT Surveillance - Alert Dashboard', ...
            'Position',[100 100 1200 680]);
        uilabel(alertFig,'Text',sprintf( ...
            'SURVEILLANCE ALERTS | Warning: %d   Urgent: %d   Emergency: %d', ...
            warningCount,urgentCount,emergencyCount), ...
            'Position',[20 635 1160 30], ...
            'FontSize',16,'FontWeight','bold');
        uilabel(alertFig,'Text', ...
            'Simulation only: verify each alert before taking action.', ...
            'Position',[20 605 1160 22], ...
            'FontSize',11);
        displayCount = min(height(incidentTable),100);
        displayTable = incidentTable(1:displayCount, ...
            {'EventID','EventDate','EventTime','CameraZone', ...
             'activity','severity','AlertLevel','AlertMessage'});
        uitable(alertFig,'Data',table2cell(displayTable), ...
            'ColumnName',displayTable.Properties.VariableNames, ...
            'Position',[20 20 1160 570]);
    catch dashboardError
        fprintf('Could not open the visual alert dashboard: %s\n', ...
            dashboardError.message);
    end
end

fprintf('\nFull event log and alert details will be saved as CSV files.\n');
%% 19. RISK SCORE GRAPH
figure(3);
bar(riskScore);
hold on;
plot([1 numTests],[0.30 0.30],'r--');
plot([1 numTests],[0.60 0.60],'m--');
plot([1 numTests],[0.80 0.80],'k--');
xlabel('Event Number');
ylabel('Risk Score');
title('Abnormal Activity Detection');
legend('Risk Score','Suspicious','High Risk','Critical');
grid on;
%% 20. ANOMALY VS CONTEXT GRAPH
figure(4);
scatter(anomalyScore,contextScore,50,riskScore,'filled');
xlabel('Anomaly Score');
ylabel('Context Score');
title('Anomaly vs Context Analysis');
colorbar;
grid on;
%% 21. PERFORMANCE GRAPH
figure(5);
metrics=[accuracy precision recall specificity balancedAccuracy f1Score];
bar(metrics);
set(gca,'XTick',1:6);
set(gca,'XTickLabel',...
 {'Accuracy','Precision','Recall','Specificity','Balanced Acc.','F1 Score'});
ylabel('Performance Percentage');
ylim([0 100]);
title('Edge AI Performance Evaluation');
grid on;
%% 22. PRIVACY SUMMARY
normalCount=sum(strcmp(severity,'NORMAL'));
suspiciousCount=sum(strcmp(severity,'SUSPICIOUS'));
highRiskCount=sum(strcmp(severity,'HIGH RISK'));
criticalCount=sum(strcmp(severity,'CRITICAL'));
fprintf('\n============= PRIVACY SUMMARY =============\n');
fprintf('Normal Events : %d\n',normalCount);
fprintf('Suspicious Events : %d\n',suspiciousCount);
fprintf('High Risk Events : %d\n',highRiskCount);
fprintf('Critical Events : %d\n',criticalCount);
%% 23. BANDWIDTH ANALYSIS
rawVideoPerEvent=2;
metadataSize=0.002;
transmittedData=zeros(numTests,1);
for i=1:numTests
 if strcmp(severity{i},'NORMAL')
 transmittedData(i)=0;
 elseif strcmp(severity{i},'SUSPICIOUS')
 transmittedData(i)=metadataSize;
 elseif strcmp(severity{i},'HIGH RISK')
 transmittedData(i)=metadataSize+0.2;
 else
 transmittedData(i)=metadataSize+1;
 end
end
totalRaw=numTests*rawVideoPerEvent;
totalTransmitted=sum(transmittedData);
savingPercentage=(1-totalTransmitted/totalRaw)*100;
fprintf('\n============= DATA PRIVACY =============\n');
fprintf('Raw Video Data : %.3f MB\n',totalRaw);
fprintf('Transmitted Data : %.3f MB\n',totalTransmitted);
fprintf('Data Reduction : %.2f %%\n',savingPercentage);
%% 24. BANDWIDTH GRAPH
figure(6);
bar([totalRaw totalTransmitted]);
set(gca,'XTickLabel',...
 {'Raw Video','Adaptive Transmission'});
ylabel('Data Size (MB)');
title('Privacy-Based Bandwidth Reduction');
grid on;
%% 25. MULTIPLE EXPERIMENTS - SAME 56 EVENT TYPES
numRuns = 5;
runAccuracy = zeros(numRuns,1);
runBalancedAccuracy = zeros(numRuns,1);
fprintf('\n========== MULTIPLE EXPERIMENTS ==========\n');

for run = 1:numRuns
    rng(100+run);
    runData = zeros(numTests,4);
    runLabel = zeros(numTests,1);
    runContext = zeros(numTests,1);

    for i = 1:numTests
        eventType = randi(56);
        eventHour = 12;
        eventLocation = '';
        eventAuthorized = 1;
        eventActivity = '';

        switch eventType
            case 1
                runData(i,:) = [1+0.30*randn,0.8+0.30*randn, ...
                    8+5*randn,0.8+0.25*randn];
                runLabel(i) = 0;
                eventActivity = 'Walking';
                eventLocation = 'Main Entrance';
                eventHour = randi([8 20]);

            case 2
                runData(i,:) = [0.1+0.08*randn,0.15+0.08*randn, ...
                    5+4*randn,0.15+0.08*randn];
                runLabel(i) = 0;
                eventActivity = 'Standing';
                eventLocation = 'Reception Area';
                eventHour = randi([8 20]);

            case 3
                runData(i,:) = [2.5+0.8*randn,2.5+0.9*randn, ...
                    20+12*randn,2.2+0.8*randn];
                runLabel(i) = 0;
                eventActivity = 'Running';
                eventLocation = 'Main Corridor';
                eventHour = randi([8 20]);

            case 4
                runData(i,:) = [0.6+0.25*randn,0.8+0.3*randn, ...
                    55+15*randn,0.9+0.3*randn];
                runLabel(i) = 0;
                eventActivity = 'Bending';
                eventLocation = 'Office Corridor';
                eventHour = randi([8 20]);

            case 5
                runData(i,:) = [0.5+0.45*randn,3+1.8*randn, ...
                    65+20*randn,3+1.8*randn];
                runLabel(i) = 1;
                eventActivity = 'Falling';
                eventLocation = 'Public Corridor';
                eventHour = randi([8 20]);

            case 6
                runData(i,:) = [1+0.65*randn,1.2+0.8*randn, ...
                    20+15*randn,1.2+0.7*randn];
                runLabel(i) = 1;
                eventActivity = 'RestrictedEntry';
                eventLocation = 'Server Room - Restricted';
                eventAuthorized = 0;
                eventHour = randi([0 5]);

            otherwise
                extraIndex = eventType-6;
                runData(i,:) = [1.4+0.9*randn,1.8+1.2*randn, ...
                    35+25*randn,1.8+1.1*randn];
                runLabel(i) = 1;
                eventHour = randi([0 23]);

                if extraIndex <= numel(extraSuspiciousActivities)
                    eventLocation = 'Security Perimeter Zone';
                    eventAuthorized = 0;
                elseif extraIndex <= numel(extraSuspiciousActivities) + ...
                        numel(extraHighRiskActivities)
                    eventLocation = 'Public Corridor Zone';
                else
                    eventLocation = 'High Security Zone';
                end
        end

        % Same context score rules as the main test set.
        score = 0;
        if contains(eventLocation,'Restricted')
            score = score+0.20;
        end
        if eventAuthorized == 0
            score = score+0.25;
        end
        if eventHour < 6 || eventHour > 22
            score = score+0.10;
        end
        if strcmp(eventActivity,'Falling')
            score = score+0.15;
        end
        runContext(i) = min(score,1);
    end

    runData = max(runData,0);
    runZ = abs((runData-repmat(mu,numTests,1))./ ...
        repmat(sigma,numTests,1));
    runAnomaly = mean(runZ,2);
    runAnomaly = runAnomaly./(1+runAnomaly);
    runRisk = 0.50*runAnomaly+0.50*runContext;
    runPrediction = double(runRisk>=bestThreshold);

    runTP = sum(runLabel==1 & runPrediction==1);
    runTN = sum(runLabel==0 & runPrediction==0);
    runFP = sum(runLabel==0 & runPrediction==1);
    runFN = sum(runLabel==1 & runPrediction==0);
    runAccuracy(run) = (runTP+runTN)/numTests*100;
    runSensitivity = runTP/(runTP+runFN+eps);
    runSpecificity = runTN/(runTN+runFP+eps);
    runBalancedAccuracy(run) = ...
        (runSensitivity+runSpecificity)/2*100;

    fprintf('Run %d Accuracy: %.2f %% | Balanced Accuracy: %.2f %%\n', ...
        run,runAccuracy(run),runBalancedAccuracy(run));
end

meanAccuracy = mean(runAccuracy);
stdAccuracy = std(runAccuracy);
meanBalancedAccuracy = mean(runBalancedAccuracy);
fprintf('\nMean Accuracy: %.2f %%\n',meanAccuracy);
fprintf('Accuracy Standard Deviation: %.2f %%\n',stdAccuracy);
fprintf('Mean Balanced Accuracy: %.2f %%\n',meanBalancedAccuracy);

%% 26. MULTIPLE EXPERIMENT GRAPH
figure(7);
bar([runAccuracy runBalancedAccuracy]);
xlabel('Experimental Run');
ylabel('Performance Percentage');
title('Performance Across Multiple Experiments');
legend('Accuracy','Balanced Accuracy');
ylim([0 100]);
grid on;
%% 27. SAVE RESULTS
writetable(T,'Edge_AI_Surveillance_Results.csv');

% Export only non-normal incidents to a separate metadata file.
% This file contains event metadata, not raw video frames.
incidentMask = ~strcmp(severity,'NORMAL');
IncidentMetadata = T(incidentMask, ...
    {'EventID','EventDate','EventTime','TimeZone','CameraZone', ...
     'activity','activityCategory','location','authorized','reason', ...
     'anomalyScore','contextScore','riskScore','predicted','severity', ...
     'AlertLevel','AlertMessage','privacyAction'});
writetable(IncidentMetadata,'Edge_AI_Incident_Metadata.csv');
fprintf('Incident metadata saved: Edge_AI_Incident_Metadata.csv\n');
fprintf('Non-normal incidents exported: %d\n',height(IncidentMetadata));

% Save a dedicated alert file for the simulated IoT monitoring dashboard.
AlertLog = T(incidentMask, ...
    {'EventID','EventDate','EventTime','TimeZone','CameraZone', ...
     'activity','severity','AlertLevel','AlertMessage','reason','riskScore'});
writetable(AlertLog,'Edge_AI_Alerts.csv');
fprintf('Alert log saved: Edge_AI_Alerts.csv\n');
fprintf('Total alerts exported: %d\n',height(AlertLog));

fprintf('\n============================================\n');
fprintf('ALL MODULES EXECUTED SUCCESSFULLY\n');
fprintf('RESULTS SAVED TO CSV FILE\n');
fprintf('============================================\n');
%% 28. 100+ ACTIVITY TAXONOMY (LABELS FOR VIDEO RECORDING)
% IMPORTANT:
% This section adds 100+ activity labels and their default risk guidance.
% It does NOT make the statistical prototype recognize these actions from
% pixels. Real automatic recognition requires labelled video training and
% a temporal action-recognition model. Review context before raising risk.
normalActivities = {
'Walking'; 'Standing'; 'Sitting'; 'Running'; 'Jogging'; 'Talking';
'Looking around'; 'Using mobile phone'; 'Reading'; 'Writing';
'Drinking water'; 'Eating'; 'Opening a door'; 'Closing a door';
'Entering a room'; 'Exiting a room'; 'Climbing stairs'; 'Descending stairs';
'Carrying a bag'; 'Carrying a box'; 'Picking up an object';
'Placing an object'; 'Waving hand'; 'Greeting someone'; 'Shaking hands'
};
workplaceActivities = {
'Working on computer'; 'Typing'; 'Using a printer'; 'Cleaning';
'Sweeping'; 'Mopping'; 'Arranging objects'; 'Moving furniture'; 'Waiting';
'Standing in a queue'; 'Discussing with another person'; 'Teaching';
'Writing on a board'; 'Operating equipment'; 'Inspecting equipment';
'Repairing equipment'; 'Delivering a package'; 'Receiving a package';
'Loading objects'; 'Unloading objects'
};
suspiciousActivities = {
'Repeatedly looking around'; 'Loitering';
'Repeatedly walking past an entrance'; 'Attempting to open a locked door';
'Entering a restricted area'; 'Remaining in a restricted area';
'Climbing over a fence'; 'Hiding behind an object';
'Crouching near a secured entrance'; 'Tampering with equipment';
'Removing an unattended object'; 'Leaving an unattended bag';
'Following another person'; 'Entering after closing hours';
'Repeatedly checking a window'; 'Trying multiple door handles';
'Unauthorized access attempt'; 'Moving around a secured perimeter';
'Concealing an object'; 'Forcing open a door'
};
emergencyActivities = {
'Falling'; 'Slipping'; 'Fainting'; 'Lying motionless'; 'Fighting';
'Punching'; 'Kicking'; 'Pushing another person'; 'Chasing another person';
'Aggressive physical interaction'; 'Throwing an object'; 'Breaking an object';
'Breaking a window'; 'Physical assault'; 'Person collapsing';
'Sudden crowd movement'; 'Panic movement'; 'Fire evacuation';
'Smoke-related emergency'; 'Person trapped'
};
objectActivities = {
'Holding a knife'; 'Carrying a knife'; 'Placing a knife on a table';
'Using a knife for cooking'; 'Threatening with a knife';
'Brandishing a knife'; 'Holding a mobile phone'; 'Carrying a backpack';
'Carrying a suitcase'; 'Holding a bottle'; 'Holding a stick';
'Carrying a metal rod'; 'Holding scissors'; 'Carrying a tool';
'Dropping an object'
};
allActivities = [normalActivities; workplaceActivities; suspiciousActivities; ...
 emergencyActivities; objectActivities; extraAllActivities];
activityGroup = [repmat({'NORMAL'},numel(normalActivities),1); ...
 repmat({'WORKPLACE'},numel(workplaceActivities),1); ...
 repmat({'SUSPICIOUS'},numel(suspiciousActivities),1); ...
 repmat({'EMERGENCY'},numel(emergencyActivities),1); ...
 repmat({'OBJECT-RELATED'},numel(objectActivities),1); ...
 repmat({'ADDED-RISK-ACTIVITY'},numel(extraAllActivities),1)];
defaultRisk = repmat({'NORMAL'},numel(allActivities),1);
defaultReason = repmat({'Routine activity; no risk inferred from label alone'}, ...
 numel(allActivities),1);
% Suspicious labels are context flags, not proof of wrongdoing.
for k = 1:numel(suspiciousActivities)
 idx = numel(normalActivities) + numel(workplaceActivities) + k;
 defaultRisk{idx} = 'SUSPICIOUS';
 defaultReason{idx} = 'Review duration, authorization, location and time';
end
% Emergency labels require prompt human review / assistance.
for k = 1:numel(emergencyActivities)
 idx = numel(normalActivities) + numel(workplaceActivities) + ...
 numel(suspiciousActivities) + k;
 defaultRisk{idx} = 'HIGH RISK';
 defaultReason{idx} = 'Possible safety emergency; verify immediately';
end
% Object presence is not itself a threat. Only threatening use is CRITICAL.
objectStart = numel(normalActivities) + numel(workplaceActivities) + ...
 numel(suspiciousActivities) + numel(emergencyActivities);
for k = 1:numel(objectActivities)
 idx = objectStart + k;
 defaultRisk{idx} = 'NORMAL';
 defaultReason{idx} = 'Object/action needs contextual interpretation';
end
knifeThreatIdx = objectStart + find(strcmp(objectActivities,'Threatening with a knife'));
knifeBrandishIdx = objectStart + find(strcmp(objectActivities,'Brandishing a knife'));
defaultRisk{knifeThreatIdx} = 'CRITICAL';
defaultRisk{knifeBrandishIdx} = 'CRITICAL';
defaultReason{knifeThreatIdx} = 'Reported threatening knife behaviour; verify urgently';
defaultReason{knifeBrandishIdx} = 'Reported knife brandishing; verify urgently';

% Guidance for the 50 added activities.
extraStart = numel(allActivities) - numel(extraAllActivities);
for k = 1:numel(extraSuspiciousActivities)
    idx = extraStart + k;
    defaultRisk{idx} = 'SUSPICIOUS';
    defaultReason{idx} = 'Security-related behaviour; verify authorization, zone and time';
end
for k = 1:numel(extraHighRiskActivities)
    idx = extraStart + numel(extraSuspiciousActivities) + k;
    defaultRisk{idx} = 'HIGH RISK';
    defaultReason{idx} = 'Possible physical harm; prompt human review is required';
end
for k = 1:numel(extraCriticalActivities)
    idx = extraStart + numel(extraSuspiciousActivities) + ...
          numel(extraHighRiskActivities) + k;
    defaultRisk{idx} = 'CRITICAL';
    defaultReason{idx} = 'Possible severe violence or weapon threat; urgent verification required';
end
% Holding/carrying a knife or cooking with one is NOT automatically critical.
taxonomyID = (1:numel(allActivities))';
ActivityTaxonomy = table(taxonomyID,allActivities,activityGroup, ...
 defaultRisk,defaultReason, ...
 'VariableNames',{'ActivityID','ActivityName','ActivityGroup', ...
 'DefaultRiskGuidance','ReviewReason'});
fprintf('\n========== ACTIVITY TAXONOMY ==========\n');
fprintf('Activity labels added: %d\n',height(ActivityTaxonomy));
disp(ActivityTaxonomy);
writetable(ActivityTaxonomy,'Activity_Taxonomy.csv');
fprintf('Activity taxonomy saved: Activity_Taxonomy.csv\n');
%% 29. ACTIVITY LABEL LOOKUP EXAMPLE
% Use this lookup when manually annotating each recorded video clip.
% Example: activityLabel = 'Walking';
% The lookup returns guidance only; it does not visually detect the action.
activityLabel = 'Walking'; % Change to the label for the clip being reviewed
lookupIndex = find(strcmpi(ActivityTaxonomy.ActivityName,activityLabel),1);
if ~isempty(lookupIndex)
 fprintf('\nSelected activity: %s\n',ActivityTaxonomy.ActivityName{lookupIndex});
 fprintf('Default guidance : %s\n',ActivityTaxonomy.DefaultRiskGuidance{lookupIndex});
 fprintf('Review note : %s\n',ActivityTaxonomy.ReviewReason{lookupIndex});
else
 warning('Activity label "%s" is not in the taxonomy.',activityLabel);
end