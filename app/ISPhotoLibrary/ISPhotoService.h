/*
 * Copyright (C) 2013-2014 InSeven Limited.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import <Foundation/Foundation.h>

@class ISPhotoService;

@protocol ISPhotoServiceDelegate <NSObject>

- (void)photoServiceDidUpdate:(ISPhotoService *)photoService;

@end

@interface ISPhotoService : NSObject

@property (nonatomic, weak) id<ISPhotoServiceDelegate> delegate;

- (id)init;
- (void)update;

- (NSUInteger)count;
- (NSString *)itemURL:(NSUInteger)index;
- (NSString *)itemName:(NSUInteger)index;

@end
