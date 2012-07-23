//
//  ImageToDatTransformer.m
//  GroceryList
//
//  Created by pawel on 1/15/11.
//  Copyright 2011 __etcApps__. All rights reserved.
//

#import "ImageToDataTransformer.h"


@implementation ImageToDataTransformer


+ (BOOL)allowsReverseTransformation {
	return YES;
}

+ (Class)transformedValueClass {
	return [NSData class];
}


- (id)transformedValue:(id)value {
	NSData *data = UIImagePNGRepresentation(value);
	return data;
}


- (id)reverseTransformedValue:(id)value {
	UIImage *uiImage = [[[UIImage alloc] initWithData:value] autorelease];
	return uiImage;
}

@end
