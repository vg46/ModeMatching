goo = beamPath;

focalLengthList = [50.54, 60.53, 75.61, 100.88, 126.15, 151.42, 176.49, 201.76, 252.30, 302.64]*1e-3;
lensList = component.lens(focalLengthList);

%Position of fixed optical components:  Z=0 is roughly 1" after 100 mm lens
%before modulators

zM1=(10.5)*0.0254; %First steering mirror after modulators
zM2=(10.5+6.33)*.0254; % Second steering mirror
zM3= zM2+0.27; % third steering mirror
z45= zM3+14.25*0.0254; %45 degree mirror on cage mount
zCav = z45+176e-3+3.5*0.0254; %Distance to front face of top Cavity mirror
zTotal = zCav+0.146/2.0; %Distance to waist in cavity 

% put down the lenses which we want to swap for lenses in our list.
% The positions are used as initial conditions when optimizing the mode 
% overlap.
goo.addComponent(component.flatMirror(zM1,'SM1'));
goo.addComponent(component.flatMirror(zM2,'SM2'));
goo.addComponent(component.flatMirror(zM3,'SM3'));
goo.addComponent(component.flatMirror(z45,'45Deg'));
goo.addComponent(component.flatMirror(zCav,'CavMirror'));

%These lenses will be moved to optimise mode overlap with OPO beam
goo.addComponent(component.lens(0.200,zM1+(2)*.0254,'L1'));
goo.addComponent(component.lens(0.350,zM2+(10)*.0254,'L2'));

goo.targetWaist(259e-6,zTotal); %Beam waist at center of symmetric cavity
goo.seedWaist(68e-6,0.0685); % Measured beam
zdomain = -.05:.001:zTotal+0.05;

figure(266)
clf
subplot(2,1,1)
hold on
%orighandle=goo.plotBeamWidth(zdomain);
%goo.plotComponents(zdomain)

[pathList,overlapList] = goo.chooseComponents(...
                'L1',lensList,[zM1+1*0.0254 zM2-0.0254],...  % choose lens1 from the list,
                'L2',lensList.duplicate,[zM2+0.0254 zM3-0.0254],... %duplicate the list, this allows
                ...                                    %  the same component to be chosen more than once
                '-vt',.001); % set the minimum initial overlap to 0.25, if a combination of components
                             % has an overlap less than this, it will be skipped without trying to optimize the lens positions
           
% note about duplicating the list:
% If you have a box of lenses, such that you can't use the same lens twice,
% you can pass the same list to the function and it will make sure that
% each lens is used only once. If you can order as many lenses as you want,
% then duplicate the list, which makes an array of new component objects which
% are not linked to the originals.

% now let's cut out all solutions with modematching < 99%

pathList = pathList(overlapList >= 0.98);

% make an array with the combined position sensitivity of the components

sensitivityList = pathList.positionSensitivity;

% now sort in increasing sensitivity

[sensitivityList,sortIndex] = sort(sensitivityList);
pathList = pathList;

% plot the best solution
newhandle=pathList(1).plotBeamWidth(zdomain,'r');
pathList(1).plotComponents(zdomain,'r*')
pathList(1).plotBeams(zdomain,'k')

hold off
legend([newhandle],'Optimized Beam Path')
ylabel('Beam Width (m)')
xlabel('Propagation axis (m)')

subplot(2,1,2)
hold on
pathList(1).plotGouyPhase(zdomain,'wrap','b');
pathList(1).plotComponents(zdomain,'r*')
axis tight
grid on
hold off
xlabel('Propagation axis (m)')
ylabel('Gouy Phase (deg)')

% print the component list to the command window
disp(' ')
disp(' Optimized Path Component List:')
display(pathList(1).components)