// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public struct ASCollectionViewStaticContent: Identifiable
{
	public var id: Int
	public var view: AnyView
}

@available(iOS 13.0, *)
public struct ASCollectionViewItemUniqueID: Hashable
{
	var sectionIDHash: Int
	var itemIDHash: Int
	init<SectionID: Hashable, ItemID: Hashable>(sectionID: SectionID, itemID: ItemID)
	{
		sectionIDHash = sectionID.hashValue
		itemIDHash = itemID.hashValue
	}
}

@available(iOS 13.0, *)
public struct ASCollectionViewSection<SectionID: Hashable>: Hashable
{
	public var id: SectionID

	private var supplementaryViews: [String: AnyView] = [:]

	internal var dataSource: ASSectionDataSourceProtocol

	public var itemIDs: [ASCollectionViewItemUniqueID]
	{
		dataSource.getUniqueItemIDs(withSectionID: id)
	}

	// Only relevant for ASTableView
	var estimatedRowHeight: CGFloat?
	var estimatedHeaderHeight: CGFloat?
	var estimatedFooterHeight: CGFloat?

	/**
	 Initializes a  section with data

	 - Parameters:
	 	- id: The id for this section
	 	- data: The data to display in the section. This initialiser expects data that conforms to 'Identifiable'
	 	- dataID: The keypath to a hashable identifier of each data item
	 	- onCellEvent: Use this to respond to cell appearance/disappearance, and preloading events.
	 - onDragDropEvent: Define this closure to enable drag/drop and respond to events (default is nil: drag/drop disabled)
	 	- contentBuilder: A closure returning a SwiftUI view for the given data item
	 */
	public init<DataCollection: RandomAccessCollection, DataID: Hashable, Content: View> (
		id: SectionID,
		data: DataCollection,
		dataID dataIDKeyPath: KeyPath<DataCollection.Element, DataID>,
		onCellEvent: OnCellEvent<DataCollection.Element>? = nil,
		onDragDropEvent: OnDragDrop<DataCollection.Element>? = nil,
		itemProvider: ItemProvider<DataCollection.Element>? = nil,
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, CellContext) -> Content))
		where DataCollection.Index == Int
	{
		self.id = id
		dataSource = ASSectionDataSource<DataCollection, DataID, Content>(
			data: data,
			dataIDKeyPath: dataIDKeyPath,
			onCellEvent: onCellEvent,
			onDragDrop: onDragDropEvent,
			itemProvider: itemProvider,
			content: contentBuilder)
	}

	public func hash(into hasher: inout Hasher)
	{
		hasher.combine(id)
	}

	public static func ==(lhs: ASCollectionViewSection<SectionID>, rhs: ASCollectionViewSection<SectionID>) -> Bool
	{
		lhs.id == rhs.id
	}
}

// MARK: SUPPLEMENTARY VIEWS - INTERNAL
@available(iOS 13.0, *)
internal extension ASCollectionViewSection
{
	mutating func setHeaderView<Content: View>(_ view: Content?)
	{
		setSupplementaryView(view, ofKind: UICollectionView.elementKindSectionHeader)
	}

	mutating func setFooterView<Content: View>(_ view: Content?)
	{
		setSupplementaryView(view, ofKind: UICollectionView.elementKindSectionFooter)
	}

	mutating func setSupplementaryView<Content: View>(_ view: Content?, ofKind kind: String)
	{
		guard let view = view else
		{
			supplementaryViews.removeValue(forKey: kind)
			return
		}

		supplementaryViews[kind] = AnyView(view)
	}

	var supplementaryKinds: Set<String>
	{
		Set(supplementaryViews.keys)
	}

	func supplementary(ofKind kind: String) -> AnyView?
	{
		supplementaryViews[kind]
	}
}

// MARK: SUPPLEMENTARY VIEWS - PUBLIC MODIFIERS

@available(iOS 13.0, *)
public extension ASCollectionViewSection
{
	func sectionHeader<Content: View>(content: () -> Content?) -> Self
	{
		var section = self
		section.setHeaderView(content())
		return section
	}

	func sectionFooter<Content: View>(content: () -> Content?) -> Self
	{
		var section = self
		section.setFooterView(content())
		return section
	}

	func sectionSupplementary<Content: View>(ofKind kind: String, content: () -> Content?) -> Self
	{
		var section = self
		section.setSupplementaryView(content(), ofKind: kind)
		return section
	}

	func tableViewSetEstimatedSizes(rowHeight: CGFloat? = nil, headerHeight: CGFloat? = nil, footerHeight: CGFloat? = nil) -> Self
	{
		var section = self
		section.estimatedRowHeight = rowHeight
		section.estimatedHeaderHeight = headerHeight
		section.estimatedFooterHeight = footerHeight
		return section
	}
}

// MARK: STATIC CONTENT SECTION
@available(iOS 13.0, *)
public extension ASCollectionViewSection
{
	/**
	 Initializes a section with static content

	 - Parameters:
	 - id: The id for this section
	 - content: A closure returning a number of SwiftUI views to display in the collection view
	 */
	init(id: SectionID, @ViewArrayBuilder content: () -> [AnyView])
	{
		self.id = id
		dataSource = ASSectionDataSource<[ASCollectionViewStaticContent], ASCollectionViewStaticContent.ID, AnyView>(
			data: content().enumerated().map
			{
				ASCollectionViewStaticContent(id: $0.offset, view: $0.element)
			},
			dataIDKeyPath: \.id,
			content: { staticContent, _ in staticContent.view })
	}

	/**
	 Initializes a section with a single view

	 - Parameters:
	 - id: The id for this section
	 - content: A single SwiftUI views to display in the collection view
	 */
	init<Content: View>(id: SectionID, content: () -> Content)
	{
		self.id = id
		dataSource = ASSectionDataSource<[ASCollectionViewStaticContent], ASCollectionViewStaticContent.ID, AnyView>(
			data: [ASCollectionViewStaticContent(id: 0, view: AnyView(content()))],
			dataIDKeyPath: \.id,
			content: { staticContent, _ in staticContent.view })
	}
}

// MARK: IDENTIFIABLE DATA SECTION
@available(iOS 13.0, *)
public extension ASCollectionViewSection
{
	/**
	 Initializes a  section with identifiable data

	 - Parameters:
	 	- id: The id for this section
	 	- data: The data to display in the section. This initialiser expects data that conforms to 'Identifiable'
	 	- onCellEvent: Use this to respond to cell appearance/disappearance, and preloading events.
	 - onDragDropEvent: Define this closure to enable drag/drop and respond to events (default is nil: drag/drop disabled)
	 	- contentBuilder: A closure returning a SwiftUI view for the given data item
	 */
	@inlinable init<Content: View, Data: Identifiable>(
		id: SectionID,
		data: [Data],
		onCellEvent: OnCellEvent<Data>? = nil,
		onDragDropEvent: OnDragDrop<Data>? = nil,
		itemProvider: ItemProvider<Data>? = nil,
		@ViewBuilder contentBuilder: @escaping ((Data, CellContext) -> Content))
	{
		self.init(id: id, data: data, dataID: \.id, onCellEvent: onCellEvent, onDragDropEvent: onDragDropEvent, itemProvider: itemProvider, contentBuilder: contentBuilder)
	}
}
