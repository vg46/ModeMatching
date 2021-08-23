goo = beamPath;

% Calculating target waist diameter in a cavity with mirrors of different
    % curvatures (length d = 10cm, mirror curvatures R1 and R2 both concave
    % 12.7mm)
lambda = 1984e-9;
d = 0.1;
R1 = -1;
R2 = 1;
target_waist_radius = (lambda/(2*pi))^(1/2) * (d*(2*R2-d))^(1/4);   %From Laser Beams and Resonators, H. KOGELNIK AND T. LI

% Seed and target beams:
goo.seedWaistR(4.10e-4, 1.891,0,lambda); % waistSize, waistR, waistPos, lambda
goo.targetWaist(target_waist_radius,0.85,lambda); % Beam waist input mirror of symmetric cavity (radius, position, lambda)

% Position of fixed optical components (m):
zM1=0.065; % First steering mirror
zM2=0.545; % Second steering mirror
zM3=0.745; % Third steering mirror
zCav=0.8; % Distance to first cavity mirror (1st curved mirror)
zCavEnd=0.9; % Distance to end of cavity (2nd curved mirror)
zTotal = zCav+0.05; %Distance to waist in cavity, occurs in cavity centre

% Add fixed optical components as components - flatMirror(Z,label)and curvedMirror(radiusOfCurvature,Z,label)
goo.addComponent(component.flatMirror(zM1,'SM1'));
goo.addComponent(component.flatMirror(zM2,'SM2'));
goo.addComponent(component.flatMirror(zM3,'SM3'));
goo.addComponent(component.curvedMirror(R1,zCav,'CavFirstMirror'));
goo.addComponent(component.curvedMirror(R2,zCavEnd,'CavEndMirror'));
    %Add components of waveplate and PBS

zdomain = -0.05:0.001:zCavEnd+0.05;

% List of focal lengths of 1" lenses available to us (https://www.thorlabs.com/newgrouppage9.cfm?objectgroup_id=8196 or https://www.thorlabs.com/newgrouppage9.cfm?objectgroup_id=5669):
%focalLengthList = [25.3, 40, 49.8, 50, 74.7, 75, 99.7, 100, 149.5, 150, 200, 250, 500, 750, 1000] *(1e-3);
focalLengthList = [99.7, 100, 149.5, 150, 200, 250, 500, 750, 1000] *(1e-3); %Keeping just longer focal lengths
lensList = component.lens(focalLengthList);

% 2 lenses, both between SM2 and SM3. Positions will be optimised
    % for mode overlap.   lens(focalLength,Z,label)
goo.addComponent(component.lens(0.200,zM1+0.05,'L0')); %Focusing beam for EOM, <1mm diameter
goo.addComponent(component.lens(0.200,zM2+0.05,'L1')); %Cavity mode matching lenses
%goo.addComponent(component.lens(0.200,zM3-0.05,'L2'));

figure(266)
clf
subplot(2,1,1)
hold on

[pathList,overlapList] = goo.chooseComponents(...
                'L0',lensList,[zM1+0.01 zM1+0.15],...
                'L1',lensList,[zM2+0.02 zM3-0.02],...
                '-vt',.001);
                %'L2',lensList.duplicate,[zM2+0.04 zM3-0.02],...

% Cut out all solutions with modematching < 99%
pathList = pathList(overlapList >= 0.98);

% Make an array with the combined position sensitivity of the components
sensitivityList = pathList.positionSensitivity;

%Sort in increasing sensitivity
[sensitivityList,sortIndex] = sort(sensitivityList);
pathList = pathList;

% Plot the best solution
newhandle=pathList(2).plotBeamWidth(zdomain,'r');
pathList(2).plotComponents(zdomain,'r*')
pathList(2).plotBeams(zdomain,'k')

hold off
legend([newhandle],'Optimized Beam Path')
ylabel('Beam Width (m)')
xlabel('Propagation axis (m)')

subplot(2,1,2)
hold on
pathList(2).plotGouyPhase(zdomain,'wrap','b');
pathList(2).plotComponents(zdomain,'r*')
axis tight
grid on
hold off
xlabel('Propagation axis (m)')
ylabel('Gouy Phase (deg)')

% print the component list to the command window
disp(' ')
disp('pathList length:')
disp(length(pathList))
disp(' Optimized Path Component List:')
display(pathList(2).components)
