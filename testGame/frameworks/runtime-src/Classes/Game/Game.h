#pragma once
#include "cocos2d.h"
#include "string.h"
using namespace std;
USING_NS_CC;
class Game :public Ref {
private:
public:
	Game();
	~Game();
	static string getBaseVersion();
};