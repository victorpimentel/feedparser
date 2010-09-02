//
//  FPItem.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/4/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "FPItem.h"
#import "FPLink.h"
#import "FPEnclosure.h"
#import "NSDate_FeedParserExtensions.h"

@interface FPItem ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *guid;
@property (nonatomic, copy, readwrite) NSString *description;
@property (nonatomic, copy, readwrite) NSString *content;
@property (nonatomic, copy, readwrite) NSString *creator;
@property (nonatomic, copy, readwrite) NSDate *pubDate;
@property (nonatomic, copy, readwrite) NSString *author;
//For use with MediaRSS
@property (nonatomic, copy, readwrite) NSString *thumbnailURL;
// for use with itunes podcasts
@property (nonatomic, copy, readwrite) NSString *itunesAuthor;
@property (nonatomic, copy, readwrite) NSString *itunesSubtitle;
@property (nonatomic, copy, readwrite) NSString *itunesSummary;
@property (nonatomic, copy, readwrite) NSString *itunesBlock;
@property (nonatomic, copy, readwrite) NSString *itunesDuration;
@property (nonatomic, copy, readwrite) NSString *itunesKeywords;
@property (nonatomic, copy, readwrite) NSString *itunesExplict;

- (void)rss_pubDate:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)rss_link:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)atom_link:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)rss_enclosure:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
@end

@implementation FPItem
@synthesize title, link, links, guid, description, content, pubDate, author, enclosures, thumbnailURL;
@synthesize creator;
@synthesize itunesAuthor,itunesSubtitle,itunesSummary,itunesBlock,itunesDuration,itunesKeywords,itunesExplict;

+ (void)initialize {
	if (self == [FPItem class]) {
		[self registerRSSHandler:@selector(setTitle:) forElement:@"title" type:FPXMLParserTextElementType];
		[self registerRSSHandler:@selector(setAuthor:) forElement:@"author" type:FPXMLParserTextElementType];
		[self registerRSSHandler:@selector(rss_link:attributes:parser:) forElement:@"link" type:FPXMLParserTextElementType];
		[self registerRSSHandler:@selector(setGuid:) forElement:@"guid" type:FPXMLParserTextElementType];
		[self registerRSSHandler:@selector(setDescription:) forElement:@"description" type:FPXMLParserTextElementType];
		[self registerRSSHandler:@selector(rss_pubDate:attributes:parser:) forElement:@"pubDate" type:FPXMLParserTextElementType];
		[self registerRSSHandler:@selector(rss_enclosure:parser:) forElement:@"enclosure" type:FPXMLParserSkipElementType];
		
		for (NSString *key in [NSArray arrayWithObjects:@"category", @"comments", @"source", nil]) {
			[self registerRSSHandler:NULL forElement:key type:FPXMLParserSkipElementType];
		}
		// Atom
		[self registerAtomHandler:@selector(atom_link:parser:) forElement:@"link" type:FPXMLParserSkipElementType];
		// DublinCore
		[self registerTextHandler:@selector(setCreator:) forElement:@"creator" namespaceURI:kFPXMLParserDublinCoreNamespaceURI];
		// Content
		[self registerTextHandler:@selector(setContent:) forElement:@"encoded" namespaceURI:kFPXMLParserContentNamespaceURI];
		// Media RSS
		[self registerHandler:@selector(mediaRSS_attributes:parser:)forElement:@"content" namespaceURI:kFPXMLParserMediaRSSNamespaceURI type:FPXMLParserStreamElementType];
		[self registerTextHandler:@selector(mediaRSS_thumbnail:attributes:parser:) forElement:@"thumbnail" namespaceURI:kFPXMLParserMediaRSSNamespaceURI];
		
		// Podcasts
		[self registerTextHandler:@selector(setItunesAuthor:) forElement:@"author" namespaceURI:kFPXMLParserItunesPodcastNamespaceURI];
		[self registerTextHandler:@selector(setItunesSubtitle:) forElement:@"subtitle" namespaceURI:kFPXMLParserItunesPodcastNamespaceURI];
		[self registerTextHandler:@selector(setItunesSummary:) forElement:@"summary" namespaceURI:kFPXMLParserItunesPodcastNamespaceURI];
		[self registerTextHandler:@selector(setItunesBlock:) forElement:@"block" namespaceURI:kFPXMLParserItunesPodcastNamespaceURI];
		[self registerTextHandler:@selector(setItunesDuration:) forElement:@"duration" namespaceURI:kFPXMLParserItunesPodcastNamespaceURI];
		[self registerTextHandler:@selector(setItunesKeywords:) forElement:@"keywords" namespaceURI:kFPXMLParserItunesPodcastNamespaceURI];
		[self registerTextHandler:@selector(setItunesExplict:) forElement:@"explict" namespaceURI:kFPXMLParserItunesPodcastNamespaceURI];
		 
	}
}

- (id)initWithBaseNamespaceURI:(NSString *)namespaceURI {
	if (self = [super initWithBaseNamespaceURI:namespaceURI]) {
		links = [[NSMutableArray alloc] init];
		enclosures = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)rss_pubDate:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	self.pubDate = [NSDate dateWithRFC822:textValue];
}

- (void)rss_link:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	FPLink *aLink = [[FPLink alloc] initWithHref:textValue rel:@"alternate" type:nil title:nil];
	if (link == nil) {
		link = [aLink retain];
	}
	[links addObject:aLink];
	[aLink release];
}

- (void)atom_link:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	NSString *href = [attributes objectForKey:@"href"];
	if (href == nil) return; // sanity check
	FPLink *aLink = [[FPLink alloc] initWithHref:href rel:[attributes objectForKey:@"rel"] type:[attributes objectForKey:@"type"]
										   title:[attributes objectForKey:@"title"]];
	if (link == nil && [aLink.rel isEqualToString:@"alternate"]) {
		link = [aLink retain];
	}
	[links addObject:aLink];
	[aLink release];
}

-(void) mediaRSS_thumbnail:(NSString *)text attributes:(NSDictionary*)attributes parser:(NSXMLParser *)parser{
	NSString *url = [attributes objectForKey:@"url"];
	if(!url) return;
	self.thumbnailURL = url;
}

-(void) mediaRSS_attributes:(NSDictionary*)attributes parser:(NSXMLParser *)parser {
	NSString *type = [attributes objectForKey:@"type"];
	NSString *url = [attributes objectForKey:@"url"];
	if(type && url){
		if([type isEqualToString:@"image/jpeg"] || [type isEqualToString:@"image/png"])
			self.thumbnailURL = url;
	}
}

- (void)rss_enclosure:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	NSString *url = [attributes objectForKey:@"url"];
	NSString *type = [attributes objectForKey:@"type"];
	NSString *lengthStr = [attributes objectForKey:@"length"];
	if (url == nil || type == nil || lengthStr == nil) return; // sanity check
	NSUInteger length = [lengthStr integerValue];
	FPEnclosure *anEnclosure = [[FPEnclosure alloc] initWithURL:url length:length type:type];
	[enclosures addObject:anEnclosure];
	[anEnclosure release];
}

- (NSString *)content {
	return (content ?: description);
}

- (BOOL)isEqual:(id)anObject {
	if (![anObject isKindOfClass:[FPItem class]]) return NO;
	FPItem *other = (FPItem *)anObject;
	return ((title       == other->title       || [title       isEqualToString:other->title])       &&
			(link        == other->link        || [link        isEqual:other->link])                &&
			(links       == other->links       || [links       isEqualToArray:other->links])        &&
			(guid        == other->guid        || [guid        isEqualToString:other->guid])        &&
			(description == other->description || [description isEqualToString:other->description]) &&
			(content     == other->content     || [content     isEqualToString:other->content])     &&
			(pubDate     == other->pubDate     || [pubDate     isEqual:other->pubDate])             &&
			(creator     == other->creator     || [creator     isEqualToString:other->creator])     &&
			(author      == other->author      || [author      isEqualToString:other->author])      &&
			(thumbnailURL   == other->thumbnailURL   || [thumbnailURL   isEqualToString:other->thumbnailURL])   &&
			(itunesAuthor   == other->itunesAuthor   || [itunesAuthor   isEqualToString:other->itunesAuthor])   &&
			(itunesSubtitle == other->itunesSubtitle || [itunesSubtitle isEqualToString:other->itunesSubtitle]) &&
			(itunesSummary  == other->itunesSummary  || [itunesSummary  isEqualToString:other->itunesSummary])  &&
			(itunesBlock    == other->itunesBlock    || [itunesBlock    isEqualToString:other->itunesBlock])    &&
			(itunesDuration == other->itunesDuration || [itunesDuration isEqualToString:other->itunesDuration]) &&
			(itunesKeywords == other->itunesKeywords || [itunesKeywords isEqualToString:other->itunesKeywords]) &&
			(itunesExplict  == other->itunesExplict  || [itunesExplict  isEqualToString:other->itunesExplict])  &&
			(enclosures  == other->enclosures || [enclosures  isEqualToArray:other->enclosures]));
}

- (void)dealloc {
	[title release];
	[link release];
	[links release];
	[guid release];
	[description release];
	[content release];
	[pubDate release];
	[creator release];
	[author release];
	[enclosures release];
	[thumbnailURL release];
	[itunesAuthor release];
	[itunesSubtitle release];
	[itunesSummary release];
	[itunesBlock release];
	[itunesDuration release];
	[itunesKeywords release];
	[itunesExplict release];
	[super dealloc];
}

#pragma mark -
#pragma mark Coding Support

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		title = [[aDecoder decodeObjectForKey:@"title"] copy];
		link = [[aDecoder decodeObjectForKey:@"link"] retain];
		links = [[aDecoder decodeObjectForKey:@"links"] mutableCopy];
		guid = [[aDecoder decodeObjectForKey:@"guid"] copy];
		description = [[aDecoder decodeObjectForKey:@"description"] copy];
		content = [[aDecoder decodeObjectForKey:@"content"] copy];
		pubDate = [[aDecoder decodeObjectForKey:@"pubDate"] copy];
		creator = [[aDecoder decodeObjectForKey:@"creator"] copy];
		author = [[aDecoder decodeObjectForKey:@"author"] copy];
		enclosures = [[aDecoder decodeObjectForKey:@"enclosures"] mutableCopy];
		thumbnailURL = [[aDecoder decodeObjectForKey:@"thumbnailURL"] copy];
		itunesAuthor = [[aDecoder decodeObjectForKey:@"itunesAuthor"] copy];
		itunesSubtitle = [[aDecoder decodeObjectForKey:@"itunesSubtitle"] copy];
		itunesSummary = [[aDecoder decodeObjectForKey:@"itunesSummary"] copy];
		itunesBlock = [[aDecoder decodeObjectForKey:@"itunesBlock"] copy];
		itunesDuration = [[aDecoder decodeObjectForKey:@"itunesDuration"] copy];
		itunesKeywords = [[aDecoder decodeObjectForKey:@"itunesKeywords"] copy];
		itunesExplict = [[aDecoder decodeObjectForKey:@"itunesExplict"] copy];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:title forKey:@"title"];
	[aCoder encodeObject:link forKey:@"link"];
	[aCoder encodeObject:links forKey:@"links"];
	[aCoder encodeObject:guid forKey:@"guid"];
	[aCoder encodeObject:description forKey:@"description"];
	[aCoder encodeObject:content forKey:@"content"];
	[aCoder encodeObject:pubDate forKey:@"pubDate"];
	[aCoder encodeObject:creator forKey:@"creator"];
	[aCoder encodeObject:author forKey:@"author"];
	[aCoder encodeObject:enclosures forKey:@"enclosures"];
	[aCoder encodeObject:thumbnailURL forKey:@"thumbnailURL"];
	[aCoder encodeObject:itunesAuthor forKey:@"itunesAuthor"];
	[aCoder encodeObject:itunesSubtitle forKey:@"itunesSubtitle"];
	[aCoder encodeObject:itunesSummary forKey:@"itunesSummary"];
	[aCoder encodeObject:itunesBlock forKey:@"itunesBlock"];
	[aCoder encodeObject:itunesDuration forKey:@"itunesDuration"];
	[aCoder encodeObject:itunesKeywords forKey:@"itunesKeywords"];
	[aCoder encodeObject:itunesExplict forKey:@"itunesExplict"];
}

@end
