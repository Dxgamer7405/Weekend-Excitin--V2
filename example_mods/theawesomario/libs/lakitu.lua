local wpairs = {};

function wpairs.init(self, py, scrollFact)
	self.pairs = {
		'lakitu_lol', 'bullet'
	};
	self.flip = {
		true, true
	}
	self.currPair = 0;
	local scales = { 1.3, 1.8 };
	local offy = { -55, -26 };
	local offx = { -1200, -1200 };
	--local offy = { 0, 150, 40, 50, 100 };	
	for j = 0, 1 do
		for i = 1, #self.pairs do
			local objName = 'wpair_'..i;
			local imgSrc = 'mario/enemies';
			makeAnimatedLuaSprite(objName, imgSrc, 0, 0);
			setLuaSpriteScrollFactor(objName, scrollFact, scrollFact);
			addAnimationByPrefix(objName, self.pairs[i], self.pairs[i], 24, true);
			objectPlayAnimation(objName, self.pairs[i], true);
			scaleObject(objName, scales[i], scales[i]);
			addLuaSprite(objName, false);
			--setProperty(objName..'.x', -300 + (250 * (i-1)));
			setProperty(objName..'.x', py + offx[i]);
			setProperty(objName..'.y', py + offy[i]);
		end
	end
end

function wpairs.beat(self)
	if (curBeat % 30 == 0) then
		--local pair = math.random(1, #self.pairs);
		self.currPair = self.currPair + 1;
		if (self.currPair > #self.pairs) then self.currPair = 1; end
		local pair = self.currPair;
		local wlkRight = math.random(1, 100) > 50;
		local startPos, endPos;
		if (wlkRight) then
			startPos = -1500;
			endPos = 2700;
		else
			startPos = 2500;
			endPos = -1700;
		end
		local flip = self.flip[pair];
		if (not wlkRight) then flip = not flip; end
		local sufx = '';
		if (math.random(1, 100) < 17) then
			sufx = '_alt';
		end
		setProperty('wpair_'..pair..sufx..'.flipX', flip);
		setProperty('wpair_'..pair..sufx..'.x', startPos);
		doTweenX('anim:wpair_'..pair..sufx, 'wpair_'..pair..sufx, endPos, 10, 'linear');
	end
end

return wpairs;