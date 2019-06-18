//
//  ViewController.swift
//  DocView
//
//  Created by EnchantCode on 2019/03/27.
//  Copyright © 2019年 EnchantCode. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController,WKNavigationDelegate {
    
    //--components
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var DocCollectionView: UICollectionView!
    @IBOutlet weak var RefView: WKWebView!
    @IBOutlet weak var ProgressBar: UIProgressView!
    
    @IBOutlet weak var MenuViewTop: NSLayoutConstraint!
    @IBOutlet weak var HideButton: UIButton!
    
    //--var
    var LoadProgress: Float = 0.0 //読み込み状態
    var menuHide:Bool = true //メニュー表示/非表示
    var selectedIndex = 0 //選択中のインデックス
    var presentQuery = "" //最後に入力されたクエリ
    //検索サービスアイコン/バーの色
    let serviceIcon:[String] = ["DocsOracle", "PHPNet", "DocsPython", "MDN", "Qiita", "Twitter"]
    let serviceColor:[String] = ["FF0000", "8993be", "FCD132", "88D1F1", "64C914", "00ACED"]
    //--クエリ(「$$」が フィールドに入力された文字列に置き換えられる)
    let searchQuery:[String] = [
        "https://docs.oracle.com/apps/search/search.jsp?q=$$&category=java",
        "https://www.php.net/search.php?show=quickref&pattern=$$",
        "https://docs.python.org/ja/3/search.html?q=$$&check_keywords=yes&area=default",
        "https://developer.mozilla.org/ja/search?q=$$",
        "https://qiita.com/search?q=$$",
        "https://twitter.com/search?q=$$&src=typd"
    ]
    //--実際にWebKitViewに投げられる文字列
    var searchURL = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //--UISearchBarの設定
        self.searchBar.placeholder = "search"
        self.searchBar.text = "texttext"
        self.searchBar.delegate = self
        
        //--DocCollectionViewの設定
        self.DocCollectionView.dataSource = self
        self.DocCollectionView.delegate = self
        self.DocCollectionView.register(UINib(nibName: "DocCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ServiceIcon")
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width:48, height:48)
        layout.scrollDirection = .horizontal
        self.DocCollectionView.collectionViewLayout = layout
        
        //--WebKitViewの設定
        self.RefView?.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        self.RefView?.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        self.RefView.allowsBackForwardNavigationGestures = true
        loadfromQuery()
        
        //--ProgressViewの設定
        ProgressBar.setProgress(LoadProgress, animated: true)
    }
    
    //--メニューバーの表示/非表示切り替え
    @IBAction func menuhidden(_ sender: Any) {
        //--menuHide(Bool):メニュー表示/非表示
        self.MenuViewTop.constant = CGFloat(Int(truncating: NSNumber(value:menuHide)) * -56)
        self.HideButton.setTitle(["▲", "▼"][Int(truncating: NSNumber(value:menuHide))], for: UIControl.State.normal)
        self.menuHide = !(self.menuHide)
        
        //--検索バーを透明にしながら上に持っていく
        UIView.animate(withDuration: 0.3) {
            self.searchBar.alpha = CGFloat(truncating: NSNumber(value:self.menuHide))
            self.view.layoutIfNeeded()
        }
    }
    
    //--オブザーバを削除
    deinit {
        self.RefView?.removeObserver(self, forKeyPath: "loading")
        self.RefView?.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    //--オブザーバの処理
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        //--keyPathごとに処理を分ける
        switch keyPath {
            //--
            case "estimatedProgress":
                //--プログレスバーの値変更
                self.ProgressBar.setProgress(Float(self.RefView.estimatedProgress), animated: true)
                break
            
            //--
            case "loading":
                //--プログレスバーの値変更
                UIApplication.shared.isNetworkActivityIndicatorVisible = self.RefView.isLoading
                if self.RefView.isLoading {
                    self.ProgressBar.setProgress(0.1, animated: true)
                }else{
                    //読み込みが終わったら0に
                    self.ProgressBar.setProgress(0.0, animated: false)
                }
                break
            
            //--
            default:
                break
        }
    }
    
    //--WebKitViewでWebページを開く
    func loadfromQuery(){
        //--プログレスバーの色をいじる
        self.ProgressBar.tintColor = UIColor(hex:self.serviceColor[self.selectedIndex])
        
        //--クエリを更新
        var presentURL = self.searchQuery[self.selectedIndex]
        if let range = presentURL.range(of:"$$"){
            presentURL.replaceSubrange(range, with: self.presentQuery)
        }
        self.searchURL = presentURL
        print(presentURL)
        
        //--読み込む
        let url = URL(string: presentURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
        let urlRequest = URLRequest(url: url!)
        self.RefView.load(urlRequest)
    }

}

//--docCollectionViewのdatasource
extension ViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.serviceIcon.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = DocCollectionView.dequeueReusableCell(withReuseIdentifier: "ServiceIcon", for: indexPath) as! DocCollectionViewCell
        cell.DocIcon.image = UIImage(named:self.serviceIcon[indexPath.row])
        cell.DocCB.backgroundColor = UIColor(hex:self.serviceColor[indexPath.row],alpha:CGFloat(truncating: NSNumber(value: indexPath.row == self.selectedIndex)))
        
        return cell
    }
}
//--
extension ViewController:UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedIndex = indexPath.row
        loadfromQuery()
        self.DocCollectionView.reloadData()
    }
}

//--
extension ViewController: UISearchBarDelegate{
    //--編集開始時、キャンセルボタンを表示する
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.searchBar.showsCancelButton = true
        return true
    }
    
    //--編集終了時
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //--テキストフィールドに入力された値を関数に投げる
        self.presentQuery = self.searchBar.text!
        loadfromQuery()
        
        self.searchBar.resignFirstResponder() //キーボードを閉じる
    }
    
    //--キャンセルボタン押下時、ボタンを隠してテキストを初期化+フォーカスを外す
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = false
        self.searchBar.resignFirstResponder()
    }
}
