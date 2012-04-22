//
//  MyContactListener.mm
//  TunnelJoggler
//
//  Created by pawel on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MyContactListener.h"


MyContactListener::MyContactListener() : _contacts() {
}

MyContactListener::~MyContactListener() {
}

void MyContactListener::BeginContact(b2Contact* contact) {
    // We need to copy out the data because the b2Contact passed in
    // is reused.
    MyContact myContact = { contact->GetFixtureA(), contact->GetFixtureB() };
    _contacts.push_back(myContact);
}

void MyContactListener::EndContact(b2Contact* contact) {
    MyContact myContact = { contact->GetFixtureA(), contact->GetFixtureB() };
    std::vector<MyContact>::iterator pos;
    pos = std::find(_contacts.begin(), _contacts.end(), myContact);
    if (pos != _contacts.end()) {
        _contacts.erase(pos);
    }
}

void MyContactListener::PreSolve(b2Contact* contact, 
								 const b2Manifold* oldManifold) {
}

void MyContactListener::PostSolve(b2Contact* contact, 
								  const b2ContactImpulse* impulse) {
}