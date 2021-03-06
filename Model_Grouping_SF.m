clear all
%Model Parameters
phi_p = 0.6;
phi_g=0.3;
phi_l=0.35;
gamma=0.97;% rate of change of primacy gradient across groups
sigma_gp=0.02;%
sigma_L=0.02;
sigma_v=0.005;
rho=0.7;
theta=0.003;
eta_NC=0.15;% learning rate for assoication between context and group
eta_O=0.15; % output interference

% experimental details
nTrials=1000;
listlength=9;
possGroupSize=[3 3];
time_Act = 1-exp(-0.5*1);

v=zeros(nTrials, listlength); % this can be easily pre-allocated, so should be
recalled_item=zeros(nTrials,listlength);

N_O=0; % counter for non recalled items

for t=1:nTrials
    
    r=zeros(1,listlength);
    
    
    % Here is what happens in model
    % We generated a longish vector of group sizes, then find first
    % group that takes us beyond list length. We truncate that group
    % and use only the groups we need
    
    groupSize=randsample(possGroupSize,listlength,true);% random
    
    % or constant within list, but varies across lists
    %groupSize=repmat(randsample(possGroupSize,1,true),1,listlength);
    
    cumulz = cumsum(groupSize);
    numGroups = find(cumulz>=listlength, 1, 'first'); % finds first instance
    if numGroups>1
        groupSize(numGroups) = listlength-cumulz(numGroups-1);
        groupSize = groupSize(1:numGroups);
    else
        groupSize = listlength;
    end
    
    lContext = ones(1,numGroups);     % control element for list context (each group has a list context)
    List_cue=1; % only have one list at the moment
    
    % make group markers
    gContext = [];
    pContext = [];
    absP = [];
    % set control elements
    
    for gz=1:length(groupSize)
        gContext = [gContext repmat(gz,1,groupSize(gz))];
        if groupSize(gz)>1
            pContext = [pContext linspace(0,1,groupSize(gz))];
        else
            pContext = [pContext 0];
        end
        absP = [absP 1:groupSize(gz)];
    end
    
    % cue for list and group and obtain group context
    Group_cue=1; % Current group
    get_group_info=1;
    % make x attempts at recall
    out_int=zeros(1,numGroups);
    gSupp = zeros(1,numGroups);
    
    eta_LC=time_Act+randn(1,numGroups)*sigma_L; % Eq A3
    eta_gv=gamma.^(absP-1)+randn(1,listlength)*sigma_gp; %Eq A10
    
    for outpos=1:listlength
        
        if get_group_info
            % list cue and group cue to context
            
            C_LC=(eta_LC+out_int).*phi_l.^abs(List_cue-lContext); %Eq A7 - control element for list
            C_NC=zeros(1,numGroups); % control element for group cue
            C_NC(Group_cue)=eta_NC;
            
            % output interference
            %             if out_int
            %                 C_NC(out_int)=eta_O;
            %             end
            
            %cue to a particular group
            C=C_NC+C_LC; % list and group control elements added
            [max_value,Current_Group]=max(C); % select most activated
            %C(Current_Group)=1; % set control element for most activared to 1
            
            
            % output interference acts on associations to l (so C_LC)
            out_int(Current_Group) = eta_O;
            
            Current_pContext = linspace(0,1,groupSize(Current_Group));
            if length(Current_pContext)==1
                Current_pContext=0;
            end
            
            withinPos=1; % set the within group maker to 1 for new group
            
            if gSupp(Current_Group)==0
                P_CG=time_Act; % assume no effect of time
            else
                P_CG=0; % we've already retrieved this, to set group context to null
            end
            get_group_info=0; % context and Current_Group remain the same
            
            
            out_int(Current_Group)=eta_O;
            
            gSupp(Current_Group) = 1;
            
        end
        
        v_GV = eta_gv.*phi_g.^abs(Current_Group-gContext); %Eq A11
        v_GV = P_CG.*(v_GV./sum(v_GV));
        v_PV = eta_gv.*...
            phi_p.^abs(Current_pContext(withinPos)-pContext); %Eq A14
        v_PV = v_PV/sum(v_PV);
        
        % sum group and item vectors to get activation of each item
        t_v = rho*v_GV + (1-rho)*v_PV; % Eq A15
        v(t,:)=t_v;
        % noisy retrieval Eq A16
        noise=randn(1,listlength)*sigma_v;
        a=(t_v+noise).*(1-r);
        
        % activation of two highest items
        [max_value,max_idx] = max(a);
        a(max_idx) = NaN;
        second_max = max(a);
        a = max_value; % retruns max_value into a
        
        if (max_value-second_max)>theta
            recalled_item(t,outpos)=max_idx;
            r(max_idx)=1;
        else
            recalled_item(t,outpos)=0;
        end
        
        withinPos=withinPos+1;% now recall of next item of current group will be attempted
        
        % check if we have reached end of current group
        if  withinPos>groupSize(Current_Group)
            get_group_info=1;
            Group_cue=Group_cue+1; % assume next group is accessed - serial recall
            if Group_cue > numGroups
                Group_cue = numGroups;
            end
        end
    end
end

% for i=1:listlength;
%     prop(i)=numel(find(recalled_item==i))/nTrials;
% end

% serial recall scoring
prop = mean(recalled_item==repmat(1:listlength,nTrials,1));
plot(prop)
ylim([0 1]);

Av_v=mean(v);
Av_a=mean(a);
